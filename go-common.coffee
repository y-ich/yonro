###
碁カーネル
中国ルールを採用。ただし自殺手は着手禁止とする。
###
# 作者: 市川雄二
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)

Array::isEqualTo = (array) ->
    ###　配列の要素すべてが等しいか否かを返す。 ###
    return false if @length != array.length
    @every (e, i) -> e == array[i]

BOARD_SIZE = 4 # デフォルトは四路
MAX_SCORE = BOARD_SIZE * BOARD_SIZE - 2

EMPTY = 0
BLACK = 1
WHITE = 2

setBoardSize = (size) ->
    ### 碁盤のサイズを設定する。 デフォルトは4路。 ###
    BOARD_SIZE = size
    MAX_SCORE = size * size - 2

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

    [aBlack, aWhite] = a.strings()
    [bBlack, bWhite] = b.strings()
    numOfLiberties = (strings) -> strings.reduce ((sum, e) -> sum + e[1].length), 0
    switch stone
        when BLACK
            dame = (numOfLiberties(aBlack) - numOfLiberties(aWhite)) - (numOfLiberties(bBlack) - numOfLiberties(bWhite))
            return dame if dame != 0
            strings = bBlack.length - aBlack.length
            return strings if strings != 0
            aBlack = a.stringsToContacts aBlack
            bBlack = b.stringsToContacts bBlack
            return bBlack.length - aBlack.length
        when WHITE
            dame = (numOfLiberties(aWhite) - numOfLiberties(aBlack)) - (numOfLiberties(bWhite) - numOfLiberties(bBlack))
            return dame if dame != 0
            strings = bWhite.length - aWhite.length
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
        @onBoard = new Array BOARD_SIZE
        for i in [0...@onBoard.length]
            @onBoard[i] = new Array BOARD_SIZE
            for j in [0...@onBoard[i].length]
                @onBoard[i][j] = EMPTY
        for e in blacks
            @onBoard[e[0]][e[1]] = BLACK
        for e in whites
            @onBoard[e[0]][e[1]] = WHITE

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
        ###
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE]
                return false if @stateAt([x, y]) isnt board.stateAt([x, y])
        true
        ###
        @onBoard.every (column, i) -> column.isEqualTo board.onBoard[i]

    # 状態アクセスメソッド

    stateAt: (position) ->
        ### 座標の状態を返す。 ###
        @onBoard[position[0]][position[1]]

    numOf: (stone) ->
        flat = Array.prototype.concat.apply [], @onBoard
        flat.filter((e) -> e is stone).length

    deployment: ->
        ###
        現在の配置を返す。
        コンストラクタの逆関数
        ###
        blacks = []
        whites = []
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE]
                position = [x, y]
                switch @stateAt(position)
                    when BLACK then blacks.push position
                    when WHITE then whites.push position
        [blacks, whites]

    score: ->
        ###
        石の数の差を返す。
        中国ルールを採用。盤上の石の数の差が評価値。
        ###
        @numOf(BLACK) - @numOf(WHITE)

    add: (stone, position) ->
        ###
        石を座標にセットする。
        stateはBLACK, WHITEのいずれか。(本当はEMPTYもOK)
        ###
        @onBoard[position[0]][position[1]] = stone

    delete: (position) ->
        ### 座標の石をただ取る。 ###
        @add EMPTY, position

    candidates: (stone) ->
        ### stoneの手番で、合法かつ自分の眼ではない座標すべての配列を返す。 ###
        result = []
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE]
                position = [x, y]
                continue if @whoseEyeAt(position) is stone
                board = @copy()
                result.push board if board.place stone, position
        result

    stringAndLibertyAt: (position) ->
        ###
        座標の石と接続した同一石の座標の配列とその石の集合のダメの座標の配列を返す。
        接続した石の集団を連(ストリング)と呼ぶ。
        ###
        return null if @isEmptyAt position

        stone = @stateAt position
        aux = (unchecked, string, liberty) =>
            return [string, liberty] if unchecked.length == 0
            checking = unchecked.pop()
            adjacencies = adjacenciesAt checking
            equalPositions = (a, b) -> (a[0] == b[0]) and (a[1] == b[1])
            for adjacency in adjacencies
                if (@stateAt(adjacency) is stone) and (string.every (e) -> not equalPositions e, adjacency)
                    string.push adjacency
                    unchecked.push adjacency
                else if @isEmptyAt(adjacency) and (liberty.every (e) -> not equalPositions e, adjacency)
                    liberty.push adjacency
            aux unchecked, string, liberty

        aux [position], [position], []

    emptyStringAt: (position) ->
        ### 座標の空点と接続した空点の座標の配列を返す。 ###
        return null unless @isEmptyAt position

        aux = (unchecked, string) =>
            return string if unchecked.length == 0
            checking = unchecked.pop()
            adjacencies = adjacenciesAt checking
            for adjacency in adjacencies
                if @isEmptyAt(adjacency) and (string.every (e) -> not e.isEqualTo adjacency)
                    string.push adjacency
                    unchecked.push adjacency
            aux unchecked, string

        aux [position], [position]

    emptyStrings: ->
        ### 盤上の空点のストリングを返す。 ###
        result = []
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE]
                position = [x, y]
                result.push @emptyStringAt position if (@isEmptyAt position) and (result.every (s) -> s.every (e) -> not e.isEqualTo position)
        result

    strings: ->
        ### 盤上のストリングを返す。1つ目の要素が黒のストリング、2つ目の要素が白のストリング。 ###
        result = [[], []]
        for x in [0...BOARD_SIZE]
            for y in [0...BOARD_SIZE]
                position = [x, y]
                switch @stateAt position
                    when BLACK
                        if (result[0].every (g) -> g[0].every (e) -> not e.isEqualTo position)
                            result[0].push @stringAndLibertyAt position
                    when WHITE
                        if (result[1].every (g) -> g[0].every (e) -> not e.isEqualTo position)
                            result[1].push @stringAndLibertyAt position
        result

    isTouchedBetween: (a, b) ->
        ### ストリングa, bが接触しているかどうか。 ###
        for p in a
            for q in b
                return true if (Math.abs(p[0] - q[0]) == 1) and (Math.abs(p[1] - q[1]) == 1)
        false

    stringsToContacts: (strings) ->
        ### string(接続した石の集合)の配列からcontact(接続もしくは接触した石の集合)を算出して返す。 ###
        result = []
        for i in [0...strings.length]
            result[i] ?= [strings[i]]
            for j in [i + 1...strings.length]
                if @isTouchedBetween strings[i][0], strings[j][0]
                    result[i].push strings[j]
                    result[j] = result[i]
        unique = (array) ->
            result = []
            for e in array when result.indexOf(e) < 0
                result.push e
            result
        unique result

    whoseEyeAt: (position, checkings = []) ->
        ###
        座標が眼かどうか調べ、眼ならばどちらの眼かを返し、眼でないならnullを返す。
        眼の定義は、その座標が同一石で囲まれていて、囲んでいる石がその座標以外のダメを詰められないこと。
        checkingsは再帰用引数
        石をかこっている時、2目以上の空点の時、眼と判定しないので改良が必要。
        ###
        return null if not @isEmptyAt position

        adjacencies = adjacenciesAt position
        return null unless adjacencies.every((e) => @stateAt(e) is BLACK) or adjacencies.every((e) => @stateAt(e) is WHITE)

        # アルゴリズム
        # 眼を作っている石群が1つなら完全な眼。
        # 眼を作っている石群の先に眼が１つでもあれば、眼。
        stone = @stateAt adjacencies[0]
        gds0 = adjacencies.map (e) => @stringAndLibertyAt e
        gds = []
        # gds0から同じグループを除いたものがgds
        for gd0 in gds0
            if gds.length == 0 or not (gds.some (gd) -> gd[0].some (e) -> e.isEqualTo gd0[0][0])
                gds.push gd0
        if gds.length == 1 or (gds.every (gd) =>
                newCheckings = checkings.concat [position]
                gd[1].filter((e) -> not e.isEqualTo position).some (d) =>
                    checkings.some((e) -> d.isEqualTo e) or (@whoseEyeAt(d, newCheckings) is stone))
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
        [blacks, whites] = @deployment()
        new OnBoard blacks, whites

    captureBy: (position) ->
        ### 座標に置かれた石によって取ることができる相手の石を取り上げて、取り上げた石の座標の配列を返す。 ###
        capturedStone = opponentOf @stateAt position
        adjacencies = adjacenciesAt position
        captives = []
        for adjacency in adjacencies when @stateAt(adjacency) is capturedStone
            stringAndLiberty = @stringAndLibertyAt adjacency
            if stringAndLiberty[1].length == 0
                @delete e for e in stringAndLiberty[0]
                captives = captives.concat stringAndLiberty[0]
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
        @captureBy position
        [string, liberty] = @stringAndLibertyAt position
        if liberty.length == 0 # 候補を減らすために自殺手は着手禁止とする。
            @delete position
            return false
        true

    # 汎用メソッド

    toString: ->
        str = new String()
        for y in [0...BOARD_SIZE]
            for x in [0...BOARD_SIZE]
                str += switch @onBoard[x][y]
                    when BLACK then 'X'
                    when WHITE then 'O'
                    else ' '
            str += '\n'
        str
