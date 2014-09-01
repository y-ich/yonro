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
    @every (e, i) ->
        e == array[i]

BOARD_SIZE = 4
MAX_SCORE = BOARD_SIZE * BOARD_SIZE - 2

EMPTY = 0
BLACK = 1
WHITE = 2

boardsToString = (history) ->
    history.map((e) -> e.toString()).join '\n'

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

    0. 相手の石が0
    1. 自分の眼の数に差があればそれを返す。(眼形が多い手を優先する)
    2. スコアに差があればそれを返す。(石を取った手を優先する)
    3. 自分のダメの数と相手のダメの数の差に差があればそれを返す。(攻め合いに有効な手を優先する)
    4. 自分の連(string)の数に差があればそれにマイナスを掛けた値を返す。(つながる手を優先する)
    5. 自分のつながり(contact)の数に差があればそれにマイナスを掛けた値を返す。(つながる手を優先する)
    ###
    
    return MAX_SCORE if a.numOf(opponentOf stone) == 0
    return -MAX_SCORE if b.numOf(opponentOf stone) == 0

    index = if stone is BLACK then 0 else 1
    eyes = a.eyes()[index].length - b.eyes()[index].length
    if eyes != 0
        return eyes

    score = a.score() - b.score()
    if score != 0
        return if stone is BLACK then score else - score

    [aBlack, aWhite] = a.strings()
    [bBlack, bWhite] = b.strings()
    switch stone
        when BLACK
            dame = (a.numOfLiberties(BLACK) - a.numOfLiberties(WHITE)) - (b.numOfLiberties(BLACK) - b.numOfLiberties(WHITE))
            return dame if dame != 0
            strings = bBlack.length - aBlack.length
            return strings if strings != 0
            aBlack = a.stringsToContacts aBlack
            bBlack = b.stringsToContacts bBlack
            return bBlack.length - aBlack.length
        when WHITE
            dame = (a.numOfLiberties(WHITE) - a.numOfLiberties(BLACK)) - (b.numOfLiberties(WHITE) - b.numOfLiberties(BLACK))
            return dame if dame != 0
            strings = bWhite.length - aWhite.length
            return strings if strings != 0
            aWhite = a.stringsToContacts aWhite
            bWhite = b.stringsToContacts bWhite
            return bWhite.length - aWhite.length

root = exports ? window
for e in ['BLACK', 'WHITE', 'EMPTY', 'BOARD_SIZE', 'MAX_SCORE', 'opponentOf', 'adjacenciesAt', 'boardsToString', 'compare']
    root[e] = eval e
