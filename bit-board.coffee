###
碁カーネル(ビッとボードバージョン)
中国ルールを採用。ただし自殺手は着手禁止とする。
###
# 作者: 市川雄二
# (C) 2014 ICHIKAWA, Yuji (New 3 Rs)

if exports?
    { BLACK, WHITE, EMPTY, MAX_SCORE, BOARD_SIZE, MAX_SCORE, opponentOf, boardsToString, compare } = require './go-common.coffee'

positionToBit = (position) ->
    1 << (position[0] + 1 + position[1] * BIT_BOARD_SIZE)

# 初期化
BIT_BOARD_SIZE = BOARD_SIZE + 2
throw "overflow #{BIT_BOARD_SIZE * BOARD_SIZE}" if BIT_BOARD_SIZE * BOARD_SIZE > 32
ON_BOARD = (->
    result = 0
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            result |= positionToBit [x, y]
    result
    )()

countBits = (x) ->
    x -= ((x >>> 1) & 0x55555555)
    x = (x & 0x33333333) + ((x >>> 2) & 0x33333333)
    x = (x + (x >>> 4)) & 0x0F0F0F0F
    x += (x >>> 8)
    x += (x >>> 16)
    x & 0x0000003F

positionsToBits = (positions) ->
    bits = 0
    for e in positions
        bits |= positionToBit e
    bits

bitsToPositions = (bitBoard) ->
    positions = []
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            position = [x, y]
            positions.push position if bitBoard & positionToBit position
    positions

adjacent = (bitBoard) ->
    expanded = bitBoard << BIT_BOARD_SIZE
    expanded |= bitBoard << 1
    expanded |= bitBoard >>> 1
    expanded |= bitBoard >>> BIT_BOARD_SIZE
    expanded & (~ bitBoard) & ON_BOARD

stringOf = (bitBoard, seed) ->
    return 0 unless bitBoard & seed
    expanded = seed | (adjacent seed) & bitBoard
    if expanded == seed
        seed
    else
        stringOf bitBoard, expanded

captured = (objective, subjective) ->
    l = adjacent(objective) & ~ subjective
    breaths = objective & adjacent l
    objective & (~ stringOf objective, breaths)

decomposeToStrings = (bitBoard) ->
    ### 盤上の石をストリングに分解する。###
    result = []
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            position = [x, y]
            bit = positionToBit position
            if (bitBoard & bit) and result.every((b) -> (b & bit) == 0)
                result.push stringOf bitBoard, bit
    result

bitsToString = (bitBoard, char) ->
    str = ''
    for y in [0...BOARD_SIZE]
        for x in [0...BOARD_SIZE]
            str += if bitBoard & positionToBit [x, y] then 'O' else '.'
        str += '\n'
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
            blacks = []
            whites = []
            for x in [0...BOARD_SIZE]
                for y in [0...BOARD_SIZE]
                    switch Math.floor Math.random() * 3
                        when 1 then blacks.push [x, y]
                        when 2 then whites.push [x, y]
            result = new OnBoard(blacks, whites)
            return result if result.isLegal()

    constructor: (blacks, whites) ->
        ### blacks, whitesは黒石/白石のある場所の座標の配列。 ###
        if blacks? and whites?
            @black = positionsToBits blacks
            @white = positionsToBits whites
        else
            @black = 0
            @white = 0

    # 状態テストメソッド

    isEmptyAt: (position) ->
        ### 座標が空点かどうか。 ###
        switch @stateAt position
            when BLACK, WHITE then false
            else true

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
        bitPos = positionToBit position
        if @black & bitPos
            BLACK
        else if @white & bitPos
            WHITE
        else
            EMPTY

    numOf: (stone) ->
        switch stone
            when BLACK
                countBits @black
            when WHITE
                countBits @white
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
        bitPos = positionToBit position
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
        @add EMPTY, position

    candidates: (stone) ->
        ### stoneの手番で、合法かつ自分の眼ではない座標に打った局面を返す。 ###
        result = []
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE]
                position = [x, y]
                continue if @whoseEyeAt(position, true) is stone
                board = @copy()
                result.push board if board.place stone, position
        result

    stringAt: (position) ->
        board = switch @stateAt position
            when BLACK then @black
            when WHITE then @white
            else ~ (@black | @white)

        stringOf board, positionToBit position

    stringAndLibertyAt: (position) ->
        ###
        座標の石と接続した同一石の座標の配列とその石の集合のダメの座標の配列を返す。
        接続した石の集団を連(ストリング)と呼ぶ。
        ###
        opponent = switch @stateAt position
            when BLACK then @white
            when WHITE then @black
        s = @stringAt(position)
        [s, adjacent(s) & ~ opponent]

    emptyStrings: ->
        ### 盤上の空点のストリングを返す。 ###
        result = []
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE]
                position = [x, y]
                result.push @stringAt position if (@isEmptyAt position) and (result.every (s) -> not (s & positionToBit(position)))
        result

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

    whoseEyeAt: (position, genuine = false, checkings = 0) ->
        ###
        座標が眼かどうか調べ、眼ならばどちらの眼かを返し、眼でないならnullを返す。
        眼の定義は、その座標が同一石で囲まれていて、囲んでいる石がその座標以外のダメを詰められないこと。
        checkingsは再帰用引数
        石をかこっている時、2目以上の空点の時、眼と判定しないので改良が必要。
        ###
        return null if not @isEmptyAt position

        adj = adjacent positionToBit position
        if (adj & @black) is adj
            stone = BLACK
            bitBoard = @black
        else if (adj & @white) is adj
            stone = WHITE
            bitBoard = @white
        else if not genuine and (adj & (@black | @white)) is adj
            strings = decomposeToStrings(stringOf @white, (adj & @white))
            if strings.length == 1 and countBits(adjacent(strings[0]) & ~ @black) == 1 and decomposeToStrings(stringOf @black, (adj & @black)).length == 1
                return BLACK
            strings = decomposeToStrings(stringOf @black, (adj & @black))
            if strings.length == 1 and countBits(adjacent(strings[0]) & ~ @white) == 1 and decomposeToStrings(stringOf @white, (adj & @white)).length == 1
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
                liberty = adjacent(gd) & ~positionToBit position
                return true if liberty & checkings
                bitsToPositions(liberty).some (d) => # いずれかが眼
                    @whoseEyeAt(d, genuine, checkings | positionToBit position) is stone)
            stone
        else
            null

    eyes: ->
        ### 眼の座標を返す。１つ目は黒の眼、２つ目は白の眼。 ###
        result = [[], []]
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE]
                switch @whoseEyeAt [x, y]
                    when BLACK then result[0].push [x, y]
                    when WHITE then result[1].push [x, y]
        result

    # 操作メソッド

    copy: ->
        c = new OnBoard()
        c.black = @black
        c.white = @white
        c

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
        return false unless @isEmptyAt position
        @add stone, position
        @captureBy stone
        if @isLegal()
            true
        else
            @delete position
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
    for e in ['countBits', 'positionToBit', 'positionsToBits', 'bitsToPositions', 'adjacent', 'stringOf', 'captured', 'decomposeToStrings', 'boardsToString', 'compare']
        root[e] = eval e if exports?
