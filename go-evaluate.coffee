###
局面評価
中国ルールを採用。ただし自殺手は着手禁止とする。
###
# 作者: 市川雄二
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)

evaluate = (history, next) ->
    # return evalUntilDepth history, next, 100
    # 32は盤を二回埋める深さ
    for depth in [13..33] by 2
        console.log "depth: #{depth}"
        result = evalUntilDepth history, next, depth
        console.log result.toString()
        return result if isFinite result.value
    result

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
    # console.log "depth#{depth}", '\n' + board.toString()
    if (board is history[history.length - 2]) and (board is history[history.length - 3]) # 両者パス
        return new EvaluationResult board.score(), history

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
                result = if b.eyes()[0].length >= 2 and b.numOfLiberties(WHITE) <= 1
                        # 相手の石を全部取って、眼が２つあれば最大勝ちとしてみたが、眼の中に1目入っている状態でのセキの読みに失敗する。
                        # 相手の石が1目残っていても地が２つあれば最大勝ちとした。正しい命題かどうか不明。
                        new EvaluationResult MAX_SCORE, history.concat b
                    else
                        evalUntilDepth history.concat(b), opponent, depth - 1, alpha, beta
                if b.isEqualTo OnBoard.fromString '''
                        XXXX
                        X X 
                        OOXX
                        XXXX
                        '''
                    console.log "depth: #{depth}, result: #{result.value}"
                if (result.value >= MAX_SCORE) or (isNaN(result.value) and alpha.value < MAX_SCORE) or alpha.value < result.value
                    alpha = result
                if alpha.value >= beta.value
                    return beta
            return alpha
        when WHITE
            for b in nodes
                result = if b.eyes()[1].length >= 2 and b.numOfLiberties(BLACK) <= 1
                        new EvaluationResult -MAX_SCORE, history.concat b
                    else
                        evalUntilDepth history.concat(b), opponent, depth - 1, alpha, beta
                if (result.value <= -MAX_SCORE) or (beta.value > -MAX_SCORE and isNaN result.value) or beta.value > result.value
                    beta = result
                if alpha.value >= beta.value
                    return alpha
            return beta

root = exports ? window
root.evaluate = evaluate
