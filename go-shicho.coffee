###
シチョウの結論
###
# 作者: 市川雄二
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)

class EvaluationResult
    constructor: (@value, @history) ->

chaser = null
escaper = null
target = null

checkTarget = (board) ->
    strings = board.strings()
    bAtaris = strings[0].filter (e) -> e[1].length == 1
    wAtaris = strings[1].filter (e) -> e[1].length == 1
    bAtaris.concat wAtaris

chaseShicho = (board, targetPosition) ->
    escaper = board.stateAt targetPosition
    chaser = board.base.opponentOf escaper
    target = targetPosition
    result = escape [board]
    new EvaluationResult result.value, if result.value then longestSuccess else longestFail
    ###
    try
        result = escape [board]
        new EvaluationResult result.value, if result.value then longestSuccess else longestFail
    catch e
        console.error e
        alert '頭が爆発しました…'
        new EvaluationResult false, longestFail
    ###

longestFail = []
longestSuccess = []
n = 0
escape = (history) ->
    n += 1
    if n > 100000
        return new EvaluationResult false, []
    board = history[history.length - 1]
    sl = board.stringAndLibertyAt target

    strings = board.strings()
    candidates = []
    for e in strings[chaser] when e[1].length == 1
        candidates.push e[1][0] # capture move
    candidates.push sl[1][0] # escape move. priority is important

    for p in candidates
        b = board.copy()
        if not b.place(escaper, p) or history[history.length - 2]?.isEqualTo b # prohibition or koh
            continue
        result = chase history.concat b
        if result.value
            if longestSuccess.length < result.history.length
                longestSuccess = result.history
        else
            if longestFail.length < result.history.length
                longestFail = result.history
            return result
    result

chase = (history) ->
    board = history[history.length - 1]
    sl = board.stringAndLibertyAt target

    switch sl[1].length
        when 1
            b = board.copy()
            b.place chaser, sl[1][0]
            history.push b
            if longestSuccess.length < history.length
                longestSuccess = history
            new EvaluationResult true, history
        when 2
            for p in sl[1]
                b = board.copy()
                if not b.place(chaser, p) or history[history.length - 2]?.isEqualTo b # prohibition or koh
                    continue
                result = escape history.concat b
                if result.value
                    if longestSuccess.length < result.history.length
                        longestSuccess = result.history
                    return result
                else
                    if longestFail.length < result.history.length
                        longestFail = result.history
            new EvaluationResult false, []
        else
            if longestFail.length < history.length
                longestFail = history
            new EvaluationResult false, history
