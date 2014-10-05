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

boardsToString = (history) ->
    history.map((e, i) -> "##{i}\n#{e.toString()}").join '\n'

class BoardBase
    constructor: (@BOARD_SIZE) ->
        @BLACK = 0
        @WHITE = 1
        @EMPTY = 2
        @MAX_SCORE = @BOARD_SIZE * @BOARD_SIZE - 2

    opponentOf: (stone) ->
        ### 黒(BLACK)なら白(WHITE)、白(WHITE)なら黒(BLACK)を返す。 ###
        switch stone
            when @BLACK then @WHITE
            when @WHITE then @BLACK
            else throw 'error'

    adjacenciesAt: (position) ->
        ### プライベート ###
        ### 隣接する点の座標の配列を返す。 ###
        result = []
        for e in [[0, -1], [-1, 0], [1, 0], [0, 1]]
            x = position[0] + e[0]
            y = position[1] + e[1]
            result.push [x, y] if 0 <= x < @BOARD_SIZE and 0 <= y < @BOARD_SIZE
        result

root = exports ? if window? then window else {} # Node.jsかブラウザかワーカーか
for e in ['BoardBase', 'boardsToString']
    root[e] = eval e
