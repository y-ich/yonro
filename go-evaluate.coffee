###
局面評価
中国ルールを採用。ただし自殺手は着手禁止とする。
###
# 作者: 市川雄二
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)

{ BLACK, WHITE, MAX_SCORE, opponentOf, boardsToString } = require './go-common.coffee'

cache =
    black: []
    white: []
    clear: ->
        @black = []
        @white = []
    add: (next, board, result) ->
        index = result.history.indexOf board
        array = switch next
            when BLACK then @black
            when WHITE then @white
        array.push
            board: board
            result: new EvaluationResult result.value, result.history.slice index + 1
    query: (next, board) ->
        array = switch next
            when BLACK then @black
            when WHITE then @white
        for e in array when e.board.isEqualTo board
            return e.result
        null

evaluate = (history, next) ->
    # return evalUntilDepth history, next, 100
    # 32は盤を二回埋める深さ
    cache.clear()
    for depth in [5..13] by 2
        console.log "depth: #{depth}"
        result = evalUntilDepth history, next, depth
        console.log result.toString()
        return result if isFinite result.value
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

    score = a.score() - b.score()
    if score != 0
        return if stone is BLACK then score else - score

    index = if stone is BLACK then 0 else 1
    eyes = a.eyes()[index].length - b.eyes()[index].length
    if eyes != 0
        return eyes

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

class EvaluationResult
    constructor: (@value, @history) ->
    toString: ->
        "value: #{@value}\n" +
        'history:\n' + boardsToString @history

evalUntilDepth = (history, next, depth, alpha = { value: - Infinity, history: null }, beta = { value: Infinity, history: null }) ->
    ###
    historyはOnBoardインスタンスの配列
    historyの最終局面の評価値と評価値に至る手順を返す。
    nextは次の手番。
    depthは最大深度。反復進化パラメータ
    alpha, betaはαβ枝狩りパラメータ
    ###
    board = history[history.length - 1]

    if (board is history[history.length - 2]) and (board is history[history.length - 3]) # 両者パス
        return new EvaluationResult board.score(), history

    c = cache.query next, board
    return new EvaluationResult c.value, history.concat c.history if c?

    if depth == 0
        return new EvaluationResult NaN, history

    opponent = opponentOf next
    candidates = board.candidates next

    parity = history.length % 2
    nodes = candidates.filter (b) ->
        history.filter((e, i) -> (i % 2) == parity).every((e) -> not b.isEqualTo e)
    nodes.sort (a, b) -> - compare a, b, next
    nodes.push board # パスを追加

    switch next
        when BLACK
            for b in nodes
                # 純碁ルールでセキを探索すると長手数になる。ダメを詰めて取られた後得をしないことを確認するため。
                # ダメを詰めて取られた後の結果の発見法的判定条件が必要。
                eyes = b.eyes()
                result = if (b.numOf(WHITE) == 0 and b.emptyStrings().length >= 2) or (eyes[0].length >= 2 and b.numOfLiberties(WHITE) <= 1)
                        # 相手の石を全部取って、眼が２つあれば最大勝ちとしてみたが、眼の中に1目入っている状態でのセキの読みに失敗する。
                        # 相手の石が1目残っていても地が２つあれば最大勝ちとした。正しい命題かどうか不明。
                        new EvaluationResult MAX_SCORE, history.concat b
                    else if eyes[1].length >= 2 and b.numOfLiberties(BLACK) <= 1
                        new EvaluationResult -MAX_SCORE, history.concat b
                    else
                        evalUntilDepth history.concat(b), opponent, depth - 1, alpha, beta
                if (result.value >= MAX_SCORE) or (isNaN(result.value) and alpha.value < MAX_SCORE) or alpha.value < result.value
                    alpha = result
                if alpha.value >= beta.value
                    cache.add next, board, beta
                    return beta
            cache.add next, board, alpha unless isNaN alpha.value
            return alpha
        when WHITE
            for b in nodes
                eyes = b.eyes()
                result = if (b.numOf(BLACK) == 0 and b.emptyStrings().length >= 2) or (eyes[1].length >= 2 and b.numOfLiberties(BLACK) <= 1)
                        new EvaluationResult -MAX_SCORE, history.concat b
                    else if eyes[0].length >= 2 and b.numOfLiberties(WHITE) <= 1
                        new EvaluationResult MAX_SCORE, history.concat b
                    else
                        evalUntilDepth history.concat(b), opponent, depth - 1, alpha, beta
                if (result.value <= -MAX_SCORE) or (beta.value > -MAX_SCORE and isNaN result.value) or beta.value > result.value
                    beta = result
                if alpha.value >= beta.value
                    cache.add next, board, alpha
                    return alpha
            cache.add next, board, beta unless isNaN beta.value
            return beta

root = exports ? window
for e in ['compare', 'evaluate']
    root[e] = eval e
