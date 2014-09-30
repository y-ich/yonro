###
局面評価
中国ルールを採用。ただし自殺手は着手禁止とする。
###
# 作者: 市川雄二
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)

if exports?
    { BLACK, WHITE, EMPTY, MAX_SCORE, opponentOf, boardsToString } = require './go-common.coffee'
    { bitsToString } = require './bit-board.coffee'
DEBUG = false

cache =
    black: []
    white: []
    clear: ->
        @black = []
        @white = []
    add: (next, board, result) ->
        array = switch next
            when BLACK then @black
            when WHITE then @white
        array.push
            board: board
            result: result
        return
    query: (next, board) ->
        array = switch next
            when BLACK then @black
            when WHITE then @white
        for e in array when e.board.isEqualTo board
            index = e.result.history.indexOf e.board
            return new EvaluationResult e.result.value, e.result.history.slice index + 1
        null

evaluate = (history, next) ->
    # return evalUntilDepth history, next, 7
    # 32は盤を二回埋める深さ
    cache.clear()
    result = evalUntilDepth history, next, 0
    trueEnd = not isNaN result.value
    for depth in [(if trueEnd then 30 else 2)..30] by 1
        console.log "depth: #{depth}" if DEBUG
        result = evalUntilDepth history, next, depth, trueEnd
        console.log result.toString() if DEBUG
        unless isNaN result.value
            return result
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

    opponent = opponentOf stone
    ###
    candidates = - a.candidates(opponent).length + b.candidates(opponent).length
    if candidates != 0
        return candidates
    ###
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
            diff = bBlack.length - aBlack.length
            return diff if diff != 0
            score = a.score() - b.score()
            return score
        when WHITE
            dame = (a.numOfLiberties(WHITE) - a.numOfLiberties(BLACK)) - (b.numOfLiberties(WHITE) - b.numOfLiberties(BLACK))
            return dame if dame != 0
            strings = bWhite.length - aWhite.length
            return strings if strings != 0
            aWhite = a.stringsToContacts aWhite
            bWhite = b.stringsToContacts bWhite
            diff = bWhite.length - aWhite.length
            return diff if diff != 0
            score = b.score() - a.score()
            return score

onlySuicide = (nodes, next, board) ->
    [blacks, whites] = board.strings()
    strings = switch next
        when BLACK then blacks
        when WHITE then whites

    suicides = nodes.filter (b) ->
        strings.some (e) -> board.numOfLibertiesOf(e) > 1 and b.numOfLibertiesOf(b.stringOf e) == 1
    suicides.length == nodes.length


class EvaluationResult
    constructor: (@value, @history) ->
    copy: ->
        new EvaluationResult @value, @history

    toString: ->
        "value: #{@value}\n" +
        'history:\n' + boardsToString @history

evalUntilDepth = (history, next, depth, trueEnd = false, alpha = new EvaluationResult(- Infinity, []), beta = new EvaluationResult(Infinity, [])) ->
    ###
    historyはOnBoardインスタンスの配列
    historyの最終局面の評価値と評価値に至る手順を返す。
    nextは次の手番。
    depthは最大深度。反復進化パラメータ
    alpha, betaはαβ枝狩りパラメータ
    外部関数compareが肝。
    ###
    board = history[history.length - 1]
    if (board is history[history.length - 2]) and (board is history[history.length - 3]) # 両者パス
        return new EvaluationResult board.score(), history

    if not trueEnd
        eyes = board.eyes()
        empties = board.numOf EMPTY
        if eyes[0].length == empties or (board.numOf(WHITE) == 0 and eyes[0].length > 0)
            # 空点がすべて黒の眼ならMAX_SCORE。白を全部取って1つでも眼があればMAX_SCORE
            return new EvaluationResult MAX_SCORE, history
        if eyes[1].length == empties or (board.numOf(BLACK) == 0 and eyes[1].length > 0)
            return new EvaluationResult -MAX_SCORE, history
    if depth <= 0
        return new EvaluationResult NaN, history

    opponent = opponentOf next
    candidates = board.candidates next
    parity = history.length % 2
    nodes = candidates.filter (b) ->
        history.filter((e, i) -> (i % 2) == parity).every((e) -> not b.isEqualTo e)
    notPossibleToIterate = candidates.length == nodes.length

    c = cache.query next, board
    return new EvaluationResult c.value, history.concat c.history if c? and notPossibleToIterate

    nodes.sort (a, b) -> - compare a, b, next
    if onlySuicide nodes, next, board
        nodes.push board # パスを追加

    nan = null
    updated = false
    switch next
        when BLACK
            for b, i in nodes
                # 純碁ルールでセキを探索すると長手数になる。ダメを詰めて取られた後得をしないことを確認するため。
                # ダメを詰めて取られた後の結果の発見法的判定条件が必要。
                result = evalUntilDepth history.concat(b), opponent, (if b is board then depth else depth - 1), trueEnd, alpha, beta
                if (result.value > alpha.value) or (result.value == alpha.value and result.history.length < alpha.history.length)
                    alpha = result
                else if isNaN result.value
                    nan ?= result
                return beta if alpha.value >= beta.value
            if nan? and alpha.value < MAX_SCORE
                return nan
            cache.add next, board, alpha if notPossibleToIterate and history.every (e, i) -> e == alpha.history[i]
            return if alpha.value == -Infinity then nan else alpha
        when WHITE
            for b, i in nodes
                eyes = b.eyes()
                result = evalUntilDepth history.concat(b), opponent, (if b is board then depth else depth - 1), trueEnd, alpha, beta
                if (result.value < beta.value) or (result.value == beta.value and result.history.length < beta.history.length)
                    beta = result
                else if isNaN result.value
                    nan ?= result
                return alpha if alpha.value >= beta.value
            if nan? and beta.value > -MAX_SCORE
                return nan
            cache.add next, board, beta if notPossibleToIterate and history.every (e, i) -> e == beta.history[i]
            return if beta.value == Infinity then nan else beta

root = exports ? if window? then window else {} # Node.jsかブラウザかワーカーか
for e in ['compare', 'evaluate']
    root[e] = eval e
