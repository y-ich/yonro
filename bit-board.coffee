###
碁カーネル(ビットボードバージョン)
中国ルールを採用。ただし自殺手は着手禁止とする。
###
# 作者: 市川雄二
# (C) 2014 ICHIKAWA, Yuji (New 3 Rs)

if exports?
    { BoardBase, boardsToString } = require './go-common.coffee'

countBits = (x) ->
    ### 32bit整数の1の数を返す ###
    x -= ((x >>> 1) & 0x55555555)
    x = (x & 0x33333333) + ((x >>> 2) & 0x33333333)
    x = (x + (x >>> 4)) & 0x0F0F0F0F
    x += (x >>> 8)
    x += (x >>> 16)
    x & 0x0000003F

class BitBoardBase extends BoardBase
    constructor: (BOARD_SIZE) ->
        super BOARD_SIZE
        @BIT_BOARD_SIZE = @BOARD_SIZE + 1
        throw "32bit overflow" if @BIT_BOARD_SIZE * @BOARD_SIZE > 32
        @BITS = []
        for x in [0...@BOARD_SIZE]
            for y in [0...@BOARD_SIZE]
                @BITS.push @positionToBit [x, y]
        ###
        @BITSは位置を示すビットパターンすべての配列。
        ###
        @ON_BOARD = 0
        for b in @BITS
            @ON_BOARD |= b
        ###
        @ON_BOARDは盤上を取り出す(フレームを落とす)ためのマスク
        ###
        @BOARD_TOP = 0
        @BOARD_BOTTOM = 0
        for x in [0...@BOARD_SIZE]
            @BOARD_TOP |= @positionToBit [x, 0]
            @BOARD_BOTTOM |= @positionToBit [x, @BOARD_SIZE - 1]

    positionToBit: (position) ->
        ###
        positionに相当するbitboardを返す。
        bitboardのフォーマットは四路の場合、
        ....F....F....F....
        でFはフレーム(枠)
        ###
        1 << (position[0] + position[1] * @BIT_BOARD_SIZE)


    positionsToBits: (positions) ->
        ### positions配列の位置に1を立てたビットボードを返す。 ###
        bits = 0
        for e in positions
            bits |= @positionToBit e
        bits

    bitsToPositions: (bitBoard) ->
        ### ビットボード上の1の位置の配列を返す。 ###
        positions = []
        for x in [0...@BOARD_SIZE]
            for y in [0...@BOARD_SIZE]
                position = [x, y]
                positions.push position if bitBoard & @positionToBit position
        positions

    adjacent: (bitBoard) ->
        ### 呼吸点を返す。 ###
        expanded = bitBoard << @BIT_BOARD_SIZE
        expanded |= bitBoard << 1
        expanded |= bitBoard >>> 1
        expanded |= bitBoard >>> @BIT_BOARD_SIZE
        expanded & (~ bitBoard) & @ON_BOARD

    stringOf: (bitBoard, seed) ->
        ### seedを含む連を返す。 ###
        return 0 unless bitBoard & seed

        loop
            expanded = (seed | (seed << @BIT_BOARD_SIZE) | (seed << 1) | (seed >>> 1) | (seed >>> @BIT_BOARD_SIZE)) & bitBoard
            if expanded == seed
                return expanded
            seed = expanded

    interiorOf: (region) ->
        ### 領域の内部を返す ###
        regionAndFrame = region | ~@ON_BOARD
        region &
        ((region << @BIT_BOARD_SIZE) | @BOARD_TOP) &
        (regionAndFrame << 1) & (regionAndFrame >>> 1) &
        ((region >>> @BIT_BOARD_SIZE) | @BOARD_BOTTOM)

    borderOf: (region) ->
        region & ~ @interiorOf region

    captured: (objective, subjective) ->
        ### subjectiveで囲まれたobjectiveの部分を返す。 ###
        liberty = @adjacent(objective) & ~ subjective
        breaths = objective & @adjacent liberty
        objective & (~ @stringOf objective, breaths)

    decomposeToStrings: (bitBoard) ->
        ### 盤上の石をストリングに分解する。###
        result = []
        checked = 0
        for bit in @BITS when bitBoard & ~ checked & bit
            string = @stringOf bitBoard, bit
            result.push string
            checked |= string
        result

    bitsToString: (bitBoard) ->
        ### bitBoardを文字列にする ###
        str = ''
        for y in [0...@BOARD_SIZE]
            for x in [0...@BOARD_SIZE]
                str += if bitBoard & @positionToBit [x, y] then 'O' else '.'
            str += '\n' unless y == @BOARD_SIZE - 1
        str

class OnBoard
    ### 盤上の状態を表すクラス ###

    @fromString: (str, base) ->
        ### 盤上の状態を表すX(黒)とO(白)と空点(スペース)と改行で文字列からインスタンスを生成する。 ###
        blacks = []
        whites = []
        lines = str.replace(/(\r?\n)*$/, '').split /\r?\n/

        for line, y in lines
            for x in [0...line.length]
                switch line.charAt x
                    when 'X' then blacks.push [x, y]
                    when 'O' then whites.push [x, y]
                    when ' ' then null ## pass
                    else throw 'bad format'

        new OnBoard base ? new BitBoardBase(lines.length), blacks, whites

    @random: (base, boardSize = null) ->
        ### ランダムな配置の碁盤を返す。 ###
        base ?= new BitBoardBase boardSize
        loop
            blacks = 0
            whites = 0
            for bitPos in base.BITS
                switch Math.floor Math.random() * 3
                    when 1 then blacks |= bitPos
                    when 2 then whites |= bitPos
            result = new OnBoard base, blacks, whites
            return result if result.isLegal()

    constructor: (@base, blacks, whites) ->
        ### blacks, whitesは黒石/白石のある場所の座標の配列。 ###
        if blacks instanceof Array and whites instanceof Array
            @black = @base.positionsToBits blacks
            @white = @base.positionsToBits whites
        else if typeof blacks is 'number' and typeof whites is 'number'
            @black = blacks
            @white = whites
        else
            @black = 0
            @white = 0

    # 状態テストメソッド

    isEmptyAt: (position) ->
        ### 座標が空点かどうか。 ###
        @_isEmptyAt @base.positionToBit position

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
        @base.captured(@black, @white) == 0 and @base.captured(@white, @black) == 0

    isEqualTo: (board) ->
        ### 盤上が同じかどうか。 ###
        if typeof board is 'string'
            board = OnBoard.fromString board
        @black == board.black and @white == board.white

    # 状態アクセスメソッド

    stateAt: (position) ->
        ### 座標の状態を返す。 ###
        @_stateAt @base.positionToBit position

    _stateAt: (bitPos) ->
        if @black & bitPos
            @base.BLACK
        else if @white & bitPos
            @base.WHITE
        else
            @base.EMPTY

    numOf: (stone) ->
        ### 盤上の石または空点の数を返す。 ###
        countBits switch stone
            when @base.BLACK then @black
            when @base.WHITE then @white
            when @base.EMPTY then @_empties()
            else
                throw 'numOf'
                0

    deployment: ->
        ###
        現在の配置を返す。
        コンストラクタの逆関数
        ###
        [@base.bitsToPositions(@black), @base.bitsToPositions(@white)]

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
        @_add stone, @base.positionToBit position

    _add: (stone, bitPos) ->
        switch stone
            when @base.BLACK
                @black |= bitPos
                @white &= ~bitPos
            when @base.WHITE
                @white |= bitPos
                @black &= ~bitPos
            when @base.EMPTY
                @black &= ~bitPos
                @white &= ~bitPos
            else
                throw 'add: unknown stone type'
        return

    delete: (position) ->
        ### 座標の石をただ取る。 ###
        @_delete @base.positionToBit position

    _delete: (bitPos) ->
        @black &= ~bitPos
        @white &= ~bitPos

    candidates: (stone) ->
        ###
        stoneの手番で、合法かつ自分の眼ではない座標に打った局面を返す。
        合法かつ自分の眼ではない座標がない場合、生きている石の目を埋める。
        ###
        result = []
        for bitPos in @base.BITS
            continue if @_whoseEyeAt(bitPos, true) is stone
            board = @copy()
            result.push board if board._place stone, bitPos
        return result if result.length > 0

        closures = @closureAndRegionsOf stone
        enclosedRegion = @enclosedRegionOf stone
        for c in closures
            eyes = @base.decomposeToStrings c & enclosedRegion
            if eyes.length > 2
                # ここではeyesのそれぞれは1bitのはず。
                for e in eyes
                    board = @copy()
                    result.push board if board._place stone, e
        result

    stringAt: (position) ->
        @stringOf @base.positionToBit position

    stringOf: (bitPos) ->
        board = switch @_stateAt bitPos
            when @base.BLACK then @black
            when @base.WHITE then @white
            else @_empties()

        @base.stringOf board, bitPos

    stringAndLibertyAt: (position) ->
        ###
        座標の石と接続した同一石の座標の配列とその石の集合のダメの座標の配列を返す。
        接続した石の集団を連(ストリング)と呼ぶ。
        ###
        s = @stringAt position
        [s, @_libertyOf s]

    _libertyOf: (string) ->
        opponent = if @black & string then @white else @black
        @base.adjacent(string) & ~ opponent

    numOfLibertiesOf: (string) ->
        countBits @_libertyOf string

    _empties: ->
        @base.ON_BOARD & ~ (@black | @white)

    emptyStrings: ->
        ### 盤上の空点のストリングを返す。 ###
        @base.decomposeToStrings @_empties()

    numOfLiberties: (stone) ->
        switch stone
            when @base.BLACK
                self = @black
                opponent = @white
            when @base.WHITE
                self = @white
                opponent = @black
        lib = @base.adjacent(self) & ~ opponent
        countBits lib

    strings: ->
        ### 盤上のストリングを返す。1つ目の要素が黒のストリング、2つ目の要素が白のストリング。 ###
        [@stringsOf(@base.BLACK), @stringsOf(@base.WHITE)]

    stringsOf: (stone) ->
        @base.decomposeToStrings switch stone
            when @base.BLACK then @black
            when @base.WHITE then @white

    isTouchedBetween: (a, b) ->
        ### ストリングa, bが接触しているかどうか。 ###
        (@base.adjacent(a) | b) != 0

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
        @_whoseEyeAt @base.positionToBit(position), genuine

    _whoseEyeAt: (bitPos, genuine = false, checkings = 0, bEnclosed = null, wEnclosed = null) ->
        ###
        座標が眼かどうか調べ、眼ならばどちらの眼かを返し、眼でないならnullを返す。
        眼の定義は、その座標が同一石で囲まれていて、囲んでいる石がその座標以外のダメを詰められないこと。
        checkingsは再帰用引数
        石をかこっている時、2目以上の空点の時、眼と判定しないので改良が必要。
        ###
        return null if not @_isEmptyAt bitPos

        bEnclosed ?= @enclosedRegionOf @base.BLACK
        if bEnclosed & bitPos
            stone = @base.BLACK
            bitBoard = @black
            region = @base.stringOf bEnclosed, bitPos
        else
            wEnclosed ?= @enclosedRegionOf @base.WHITE
            if wEnclosed & bitPos
                stone = @base.WHITE
                bitBoard = @white
                region = @base.stringOf wEnclosed, bitPos
            else
                return null

        return null if genuine and countBits(region) > 1

        # アルゴリズム
        # 眼を作っている石群が1つなら完全な眼。
        # 眼を作っている石群の先に眼が１つでもあれば、眼。
        gds = @base.decomposeToStrings @base.stringOf bitBoard, @base.adjacent region
        if gds.length == 1 or # 眼を作っている石群が1つ
            (gds.every (gd) =>
                liberty = @base.adjacent(gd) & ~region
                return true if liberty & checkings
                return true for b in @base.BITS when (b & liberty) and @_whoseEyeAt(b, genuine, checkings | bitPos, bEnclosed, wEnclosed) is stone
                false)
            stone
        else
            null

    eyesOf: (stone) ->
        result = []
        bEnclosed = @enclosedRegionOf stone
        regions = @base.decomposeToStrings bEnclosed
        bitBoard = switch stone
                when @base.BLACK then @black
                when @base.WHITE then @white
        for r in regions
            strings = @base.decomposeToStrings @base.stringOf bitBoard, @base.adjacent r
            empties = r &  @_empties()
            if strings.every((s) => (empties & @base.adjacent s) is empties)
                result.push r
        result

    eyes: ->
        ### 眼の座標を返す。１つ目は黒の眼、２つ目は白の眼。 ###
        blacks = @eyesOf @base.BLACK
        whites = @eyesOf @base.WHITE
        [(b for b in blacks when whites.every (w) -> (w & b) == 0), (w for w in whites when blacks.every (b) -> (w & b) == 0)]

    enclosedRegionOf: (stone) ->
        switch stone
            when @base.BLACK
                self = @black
                opponent = @white
            when @base.WHITE
                self = @white
                opponent = @black
        regions = ~self & @base.ON_BOARD
        interiors = @base.interiorOf regions
        regions & ~@base.stringOf regions, interiors & ~opponent

    closureAndRegionsOf: (stone) ->
        region = @enclosedRegionOf stone
        neighoring = @base.stringOf (switch stone
            when @base.BLACK then @black
            when @base.WHITE then @white), @base.adjacent region
        @base.decomposeToStrings neighoring | region

    atari: ->
        @base.bitsToPositions @_atari()

    _atari: ->
        result = 0
        strings = [].concat.apply [], @strings()
        result |= s for s in strings when @numOfLibertiesOf(s) == 1
        result

    # 操作メソッド

    copy: ->
        new OnBoard(@base, @black, @white)

    captureBy: (stone) ->
        ### 相手の石を取り上げて、取り上げた石のビットボードを返す。 ###
        switch stone
            when @base.BLACK
                captives = @base.captured @white, @black
                @white &= ~captives
            when @base.WHITE
                captives = @base.captured @black, @white
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
        @_place stone, @base.positionToBit position

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
        for y in [0...@base.BOARD_SIZE]
            for x in [0...@base.BOARD_SIZE]
                str += switch @stateAt [x, y]
                    when @base.BLACK then 'X'
                    when @base.WHITE then 'O'
                    else ' '
            str += '\n' unless y == @base.BOARD_SIZE - 1
        str


root = exports ? if window? then window else {}
root.OnBoard = OnBoard
root.BitBoardBase = BitBoardBase
if exports?
    for e in ['countBits']
        root[e] = eval e if exports?
