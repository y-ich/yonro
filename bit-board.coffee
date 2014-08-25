###
碁カーネル
中国ルールを採用。ただし自殺手は着手禁止とする。
###
# 作者: 市川雄二
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)

# 座標(position)の原点は[0, 0]

Array::isEqualTo = (array) ->
    ###　配列の要素すべてが等しいか否かを返す。 ###
    return false if @length != array.length
    @every (e, i) -> e == array[i]

BOARD_SIZE = null
BIT_BOARD_SIZE = null
ON_BOARD = null
MAX_SCORE = null

EMPTY = 0
BLACK = 1
WHITE = 2

setBoardSize = (size) ->
    ### 碁盤のサイズを設定する。 デフォルトは4路。 ###
    BOARD_SIZE = size
    BIT_BOARD_SIZE = BOARD_SIZE + 2
    throw "overflow #{BIT_BOARD_SIZE * BOARD_SIZE}" if BIT_BOARD_SIZE * BOARD_SIZE > 32

    ON_BOARD = 0
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            ON_BOARD |= positionToBit [x, y]

    MAX_SCORE = BOARD_SIZE * BOARD_SIZE - 2


opponentOf = (stone) ->
    ### 黒(BLACK)なら白(WHITE)、白(WHITE)なら黒(BLACK)を返す。 ###
    switch stone
        when BLACK then WHITE
        when WHITE then BLACK
        else throw 'error'

adjacenciesAt = (position) ->
    ### プライベート ###
    ### 隣接する点の座標の配列を返す。 ###
    result = []
    for e in [[0, -1], [-1, 0], [1, 0], [0, 1]]
        x = position[0] + e[0]
        y = position[1] + e[1]
        result.push [x, y] if 0 <= x < BOARD_SIZE and 0 <= y < BOARD_SIZE
    result

compare = (a, b, stone) ->
    ###
    探索のための優先順位を決める局面比較関数。
    a, bは比較する局面。stoneの立場で比較し、結果を整数値で返す。

    1. スコアに差があればそれを返す。(石を取った手を優先する)
    2. 自分の眼の数に差があればそれを返す。(眼形が多い手を優先する)
    3. 自分のダメの数と相手のダメの数の差に差があればそれを返す。(攻め合いに有効な手を優先する)
    4. 自分の連(string)の数に差があればそれにマイナスを掛けた値を返す。(つながる手を優先する)
    5. 自分のつながり(contact)の数に差があればそれにマイナスを掛けた値を返す。(つながる手を優先する)
    ###
    score = a.score() - b.score()
    if score != 0
        return if stone is BLACK then score else - score

    index = if stone is BLACK then 0 else 1
    eyes = a.eyes()[index].length - b.eyes()[index].length
    if eyes != 0
        return eyes

    switch stone
        when BLACK
            dame = (a.numOfLiberties(BLACK) - a.numOfLiberties(WHITE)) - (b.numOfLiberties(BLACK) - b.numOfLiberties(WHITE))
            return dame if dame != 0
            strings = b.strings()[0].length - a.strings()[0].length
            return strings if strings != 0
            aBlack = a.stringsToContacts aBlack
            bBlack = b.stringsToContacts bBlack
            return bBlack.length - aBlack.length
        when WHITE
            dame = (a.numOfLiberties(WHITE) - a.numOfLiberties(BLACK)) - (b.numOfLiberties(WHITE) - b.numOfLiberties(BLAC))
            return dame if dame != 0
            strings = b.strings()[1].length - a.strings()[1].length
            return strings if strings != 0
            aWhite = a.stringsToContacts aWhite
            bWhite = b.stringsToContacts bWhite
            return bWhite.length - aWhite.length


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
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE] when not @isEmptyAt [x, y]
                [g, d] = @stringAndLibertyAt [x, y]
                return false if d.length == 0
        true

    isEqualTo: (board) ->
        ### 盤上が同じかどうか。 ###
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
                continue if @whoseEyeAt(position) is stone
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
        [s, adjacent s & ~ opponent]

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

    whoseEyeAt: (position, checkings = 0) ->
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
        else
            stone = null
            bitBoard = null
        return null unless stone?

        # アルゴリズム
        # 眼を作っている石群が1つなら完全な眼。
        # 眼を作っている石群の先に眼が１つでもあれば、眼。
        gds = decomposeToStrings stringOf bitBoard, adj
        console.log '\n'
        console.log bitsToString stringOf bitBoard, adj
        console.log bitsToString(bitBoard)
        console.log bitsToString(adj)
        if gds.length == 1 or # 眼を作っている石群が1つ
            (gds.every (gd) => # すべての連の
                liberty = adjacent(gd) & ~positionToBit position
                return true if liberty & checkings
                bitsToPositions(liberty).some (d) => # いずれかが眼
                    @whoseEyeAt(d, checkings | positionToBit position) is stone)
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
        ### 座標に置かれた石によって取ることができる相手の石を取り上げて、取り上げた石のビットボードを返す。 ###
        objective = switch stone
            when BLACK then @white
            when WHITE then @black
        subjective = switch stone
            when BLACK then @black
            when WHITE then @white
        captives = captured objective, subjective
        switch stone
            when BLACK
                @white &= ~captives
            when WHITE
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
        [string, liberty] = @stringAndLibertyAt position
        if countBits(liberty) == 0 # 候補を減らすために自殺手は着手禁止とする。
            @delete position
            return false
        true

    # 汎用メソッド

    toString: ->
        str = new String()
        for y in [0...BOARD_SIZE]
            for x in [0...BOARD_SIZE]
                str += switch @stateAt [x, y]
                    when BLACK then 'X'
                    when WHITE then 'O'
                    else ' '
            str += '\n'
        str

countBits = (x) ->
    x -= ((x >>> 1) & 0x55555555)
    x = (x & 0x33333333) + ((x >>> 2) & 0x33333333)
    x = (x + (x >>> 4)) & 0x0F0F0F0F
    x += (x >>> 8)
    x += (x >>> 16)
    x & 0x0000003F

positionToBit = (position) ->
    1 << (position[0] + 1 + position[1] * BIT_BOARD_SIZE)

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
    breaths = adjacent l
    objective & (~ stringOf objective, breaths)

decomposeToStrings = (bitBoard) ->
    ### 盤上の石をストリングに分解する。###
    result = []
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            position = [x, y]
            bit = positionToBit position
            if (bitBoard & bit) and result.every((b) -> (b & bit) == 0)
                console.log bitsToString stringOf bitBoard, bit
                result.push stringOf bitBoard, bit
    result

bitsToString = (bitBoard, char) ->
    str = new String()
    for y in [0...BOARD_SIZE]
        for x in [0...BOARD_SIZE]
            str += if bitBoard & positionToBit [x, y] then 'O' else '.'
        str += '\n'
    str

# 初期化
setBoardSize 4 # デフォルトは四路

root = exports ? window
for e in ['OnBoard', 'BLACK', 'WHITE', 'EMPTY', 'MAX_SCORE', 'opponentOf']
    root[e] = eval e
if exports?
    for e in ['countBits', 'positionToBit', 'positionsToBits', 'bitsToPositions', 'adjacent', 'stringOf', 'captured', 'decomposeToStrings']
        root[e] = eval e if exports?
