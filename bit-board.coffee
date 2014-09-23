###
碁カーネル(ビッとボードバージョン)
中国ルールを採用。ただし自殺手は着手禁止とする。
###
# 作者: 市川雄二
# (C) 2014 ICHIKAWA, Yuji (New 3 Rs)

if exports?
    { BLACK, WHITE, EMPTY, MAX_SCORE, BOARD_SIZE, MAX_SCORE, opponentOf, boardsToString, compare } = require './go-common.coffee'

positionToBit = (position) ->
    ###
    positionに相当するbitboardを返す。
    bitboardのフォーマットは四路の場合、
    ....F....F....F....
    でFはフレーム(枠)
    ###
    1 << (position[0] + position[1] * BIT_BOARD_SIZE)

# 初期化
BIT_BOARD_SIZE = BOARD_SIZE + 1
throw "overflow #{BIT_BOARD_SIZE * BOARD_SIZE}" if BIT_BOARD_SIZE * BOARD_SIZE > 32

_BITS = (->
    result = []
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            result.push positionToBit [x, y]
    result
    )()
###
_BITSは位置を示すビットパターンすべての配列。
###

ON_BOARD = (->
    result = 0
    for b in _BITS
        result |= b
    result
    )()
###
ON_BOARDは盤上を取り出す(フレームを落とす)ためのマスク
###

countBits = (x) ->
    ### 32bit整数の1の数を返す ###
    x -= ((x >>> 1) & 0x55555555)
    x = (x & 0x33333333) + ((x >>> 2) & 0x33333333)
    x = (x + (x >>> 4)) & 0x0F0F0F0F
    x += (x >>> 8)
    x += (x >>> 16)
    x & 0x0000003F

positionsToBits = (positions) ->
    ### positions配列の位置に1を立てたビットボードを返す。 ###
    bits = 0
    for e in positions
        bits |= positionToBit e
    bits

bitsToPositions = (bitBoard) ->
    ### ビットボード上の1の位置の配列を返す。 ###
    positions = []
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            position = [x, y]
            positions.push position if bitBoard & positionToBit position
    positions

adjacent = (bitBoard) ->
    ### 呼吸点を返す。 ###
    expanded = bitBoard << BIT_BOARD_SIZE
    expanded |= bitBoard << 1
    expanded |= bitBoard >>> 1
    expanded |= bitBoard >>> BIT_BOARD_SIZE
    expanded & (~ bitBoard) & ON_BOARD

stringOf = (bitBoard, seed) ->
    ### seedを含む連を返す。 ###
    return 0 unless bitBoard & seed

    loop
        expanded = (seed | (seed << BIT_BOARD_SIZE) | (seed << 1) | (seed >>> 1) | (seed >>> BIT_BOARD_SIZE)) & bitBoard
        if expanded == seed
            return expanded
        seed = expanded

interiorOf = (region) ->
    ### 領域の内部を返す ###
    region & (region << BIT_BOARD_SIZE) & (region << 1) & (region >>> 1) & (region >>> BIT_BOARD_SIZE)

borderOf = (region) ->
    region & ~ interiorOf region

captured = (objective, subjective) ->
    ### subjectiveで囲まれたobjectiveの部分を返す。 ###
    liberty = adjacent(objective) & ~ subjective
    breaths = objective & adjacent liberty
    objective & (~ stringOf objective, breaths)

decomposeToStrings = (bitBoard) ->
    ### 盤上の石をストリングに分解する。###
    result = []
    for bit in _BITS when (bitBoard & bit) and result.every((b) -> (b & bit) == 0)
        result.push stringOf bitBoard, bit
    result

bitsToString = (bitBoard) ->
    ### bitBoardを文字列にする ###
    str = ''
    for y in [0...BOARD_SIZE]
        for x in [0...BOARD_SIZE]
            str += if bitBoard & positionToBit [x, y] then 'O' else '.'
        str += '\n' unless y == BOARD_SIZE - 1
    str

class OnBoard
    ### 盤上の状態を表すクラス ###

    @fromString: (str) ->
        ### 盤上の状態を表すX(黒)とO(白)と空点(スペース)と改行で文字列からインスタンスを生成する。 ###
        blacks = []
        whites = []
        lines = str.replace(/(\r?\n)*$/, '').split /\r?\n/
        throw 'bad format' if lines.length isnt BOARD_SIZE

        for line, y in lines
            throw 'bad format' if line.length isnt BOARD_SIZE
            for x in [0...BOARD_SIZE]
                switch line.charAt x
                    when 'X' then blacks.push [x, y]
                    when 'O' then whites.push [x, y]
                    when ' ' then null ## pass
                    else throw 'bad format'

        new OnBoard blacks, whites

    @random: ->
        ### ランダムな配置の碁盤を返す。 ###
        loop
            blacks = 0
            whites = 0
            for bitPos in _BITS
                switch Math.floor Math.random() * 3
                    when 1 then blacks |= bitPos
                    when 2 then whites |= bitPos
            result = new OnBoard(blacks, whites)
            return result if result.isLegal()

    constructor: (blacks, whites) ->
        ### blacks, whitesは黒石/白石のある場所の座標の配列。 ###
        if blacks instanceof Array and whites instanceof Array
            @black = positionsToBits blacks
            @white = positionsToBits whites
        else if typeof blacks is 'number' and typeof whites is 'number'
            @black = blacks
            @white = whites
        else
            @black = 0
            @white = 0

    # 状態テストメソッド

    isEmptyAt: (position) ->
        ### 座標が空点かどうか。 ###
        @_isEmptyAt positionToBit position

    _isEmptyAt: (bitPos) ->
        ### 座標が空点かどうか。 ###
        not ((@black | @white) & bitPos)

    isLegalAt: (stone, position) ->
        ###
        座標が合法着手点かどうか。
        コウ(循環)の着手禁止はチェックしない。循環については手順関連で別途チェックすること
        ###
        board = @copy()
        board.place stone, position

    isLegal: ->
        ### 盤上の状態が合法がどうか。(ダメ詰まりの石が存在しないこと) ###
        captured(@black, @white) == 0 and captured(@white, @black) == 0

    isEqualTo: (board) ->
        ### 盤上が同じかどうか。 ###
        if typeof board is 'string'
            board = OnBoard.fromString board
        @black == board.black and @white == board.white

    # 状態アクセスメソッド

    stateAt: (position) ->
        ### 座標の状態を返す。 ###
        @_stateAt positionToBit position

    _stateAt: (bitPos) ->
        if @black & bitPos
            BLACK
        else if @white & bitPos
            WHITE
        else
            EMPTY

    numOf: (stone) ->
        ### 盤上の石または空点の数を返す。 ###
        countBits switch stone
            when EMPTY then @_empties()
            when BLACK then @black
            when WHITE then @white
            else
                throw 'numOf'
                0

    deployment: ->
        ###
        現在の配置を返す。
        コンストラクタの逆関数
        ###
        [bitsToPositions @black, bitsToPositions @white]

    score: ->
        ###
        石の数の差を返す。
        中国ルールを採用。盤上の石の数の差が評価値。
        ###
        countBits(@black) - countBits(@white)

    add: (stone, position) ->
        ###
        石を座標にセットする。
        stateはBLACK, WHITEのいずれか。(本当はEMPTYもOK)
        ###
        @_add stone, positionToBit position

    _add: (stone, bitPos) ->
        switch stone
            when BLACK
                @black |= bitPos
                @white &= ~bitPos
            when WHITE
                @white |= bitPos
                @black &= ~bitPos
            when EMPTY
                @black &= ~bitPos
                @white &= ~bitPos
            else
                throw 'add: unknown stone type'
        return

    delete: (position) ->
        ### 座標の石をただ取る。 ###
        @_delete positionToBit position

    _delete: (bitPos) ->
        @black &= ~bitPos
        @white &= ~bitPos

    candidates: (stone) ->
        ### stoneの手番で、合法かつ自分の眼ではない座標に打った局面を返す。 ###
        result = []
        for bitPos in _BITS
            continue if @_whoseEyeAt(bitPos, true) is stone
            board = @copy()
            result.push board if board._place stone, bitPos
        result

    stringAt: (position) ->
        @stringOf positionToBit position

    stringOf: (bitPos) ->
        board = switch @_stateAt bitPos
            when BLACK then @black
            when WHITE then @white
            else @_empties()

        stringOf board, bitPos

    stringAndLibertyAt: (position) ->
        ###
        座標の石と接続した同一石の座標の配列とその石の集合のダメの座標の配列を返す。
        接続した石の集団を連(ストリング)と呼ぶ。
        ###
        s = @stringAt(position)
        [s, @_libertyOf s]

    _libertyOf: (string) ->
        opponent = if @black & string then @white else @black
        adjacent(string) & ~ opponent

    numOfLibertiesOf: (string) ->
        countBits @_libertyOf string

    _empties: ->
        ON_BOARD & ~ (@black | @white)

    emptyStrings: ->
        ### 盤上の空点のストリングを返す。 ###
        decomposeToStrings @_empties()

    numOfLiberties: (stone) ->
        switch stone
            when BLACK
                self = @black
                opponent = @white
            when WHITE
                self = @white
                opponent = @black
        lib = adjacent(self) & ~ opponent
        countBits lib

    strings: ->
        ### 盤上のストリングを返す。1つ目の要素が黒のストリング、2つ目の要素が白のストリング。 ###
        [decomposeToStrings(@black), decomposeToStrings(@white)]

    isTouchedBetween: (a, b) ->
        ### ストリングa, bが接触しているかどうか。 ###
        (adjacent(a) | b) != 0

    stringsToContacts: (strings) ->
        ### string(接続した石の集合)の配列からcontact(接続もしくは接触した石の集合)を算出して返す。 ###
        result = []
        for i in [0...strings.length]
            result[i] ?= [strings[i]]
            for j in [i + 1...strings.length]
                if @isTouchedBetween strings[i], strings[j]
                    result[i].push strings[j]
                    result[j] = result[i]
        unique = (array) ->
            result = []
            for e in array when result.indexOf(e) < 0
                result.push e
            result
        unique result

    whoseEyeAt: (position, genuine = false) ->
        @_whoseEyeAt positionToBit(position), genuine

    _whoseEyeAt: (bitPos, genuine = false, checkings = 0) ->
        ###
        座標が眼かどうか調べ、眼ならばどちらの眼かを返し、眼でないならnullを返す。
        眼の定義は、その座標が同一石で囲まれていて、囲んでいる石がその座標以外のダメを詰められないこと。
        checkingsは再帰用引数
        石をかこっている時、2目以上の空点の時、眼と判定しないので改良が必要。
        ###
        return null if not @_isEmptyAt bitPos

        emptyString = @stringOf bitPos
        return null if countBits(emptyString) >= 8 # 8は最小限の生きがある大きさ

        adj = adjacent emptyString
        if adj == 0
            stone = null
        else if (adj & @black) is adj
            stone = BLACK
            bitBoard = @black
        else if (adj & @white) is adj
            stone = WHITE
            bitBoard = @white
        else if not genuine
            strings = decomposeToStrings(stringOf @white, (adj & @white))
            if strings.length == 1 and countBits(adjacent(strings[0]) & ~ @black) == 1 and decomposeToStrings(stringOf @black, (adj & @black)).map((e) => countBits @_libertyOf(e)).every((e) -> e > 1)
                return BLACK
            strings = decomposeToStrings(stringOf @black, (adj & @black))
            if strings.length == 1 and countBits(adjacent(strings[0]) & ~ @white) == 1 and decomposeToStrings(stringOf @white, (adj & @white)).map((e) => countBits @_libertyOf(e)).every((e) -> e > 1)
                return WHITE
            stone = null
            bitBoard = null
        else
            stone = null
            bitBoard = null
        return null unless stone?

        # アルゴリズム
        # 眼を作っている石群が1つなら完全な眼。
        # 眼を作っている石群の先に眼が１つでもあれば、眼。
        gds = decomposeToStrings stringOf bitBoard, adj
        if gds.length == 1 or # 眼を作っている石群が1つ
            (gds.every (gd) => # すべての連の
                liberty = adjacent(gd) & ~bitPos
                return true if liberty & checkings
                return true for b in _BITS when (b & liberty) and @_whoseEyeAt(b, genuine, checkings | bitPos) is stone
                false)
            stone
        else
            null

    eyes: ->
        ### 眼の座標を返す。１つ目は黒の眼、２つ目は白の眼。 ###
        result = [[], []]
        for b in @emptyStrings()
            switch @_whoseEyeAt b
                when BLACK then result[0].push b
                when WHITE then result[1].push b
        result

    enclosedResionsOf: (stone) ->
        switch stone
            when BLACK
                self = @black
                opponent = @white
            when WHITE
                self = @white
                opponent = @black
        regions = decomposeToStrings ~self & ON_BOARD
        regions.filter (r) ->
            i = interiorOf r
            (i & opponent) == i


    # 操作メソッド

    copy: ->
        new OnBoard(@black, @white)

    captureBy: (stone) ->
        ### 相手の石を取り上げて、取り上げた石のビットボードを返す。 ###
        switch stone
            when BLACK
                captives = captured @white, @black
                @white &= ~captives
            when WHITE
                captives = captured @black, @white
                @black &= ~captives
        captives

    place: (stone, position) ->
        ###
        石を座標に着手する。
        着手候補を減らす便宜上、自殺手は着手禁止とする。(中国ルールからの逸脱)
        着手が成立したらtrue。着手禁止の場合false。
        循環手か否かは未チェック。
        ###
        return true unless position? # パス
        @_place stone, positionToBit position

    _place: (stone, bitPos) ->
        return false unless @_isEmptyAt bitPos
        @_add stone, bitPos
        @captureBy stone
        if @isLegal()
            true
        else
            @_delete bitPos
            false

    # 汎用メソッド

    toString: ->
        str = ''
        for y in [0...BOARD_SIZE]
            for x in [0...BOARD_SIZE]
                str += switch @stateAt [x, y]
                    when BLACK then 'X'
                    when WHITE then 'O'
                    else ' '
            str += '\n' unless y == BOARD_SIZE - 1
        str


root = exports ? window
root.OnBoard = OnBoard
if exports?
    for e in ['countBits', 'positionToBit', 'positionsToBits', 'bitsToPositions', 'adjacent', 'stringOf', 'captured', 'decomposeToStrings', 'boardsToString', 'compare', 'bitsToString']
        root[e] = eval e if exports?
