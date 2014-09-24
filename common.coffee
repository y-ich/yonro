###
四路の純碁とソルバのクライアント側共通コード
###
# 四路の碁(仮名)
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)

responseInterval = 2000


wEvaluate = (history, next, success, error, timeout = 10000) ->
    ###
    (web workerを使って)局面を評価する。

    success, errorはコールバック関数。
    ###

    $('#evaluating').css 'display', 'inline'

    timeid = null

    worker = new Worker 'go-worker.js'
    worker.onmessage = (event) ->
        $('#evaluating').css 'display', 'none'
        clearTimeout timeid
        if event.data.error?
            error event.data.error
        else
            success
                value: event.data.value
                history: event.data.history.map (e) -> OnBoard.fromString e
    worker.postMessage
        history: history.map (e) -> e.toString()
        next: next

    timeid = setTimeout (->
            $('#evaluating').css 'display', 'none'
            worker.terminate()
            error
                message: 'timeout'
        ), timeout


showOnBoard = (board, effect = false, callback = ->) ->
    ###
    boardの状態を描画する。
    boardがnullなら空の盤。
    effectをtrueにすると、今の状態からエフェクト入りで盤を変更。
    ###
    if not board?
        $('.intersection').removeClass 'black white half-opacity beat'
        return

    [blacks, whites] = board.deployment()
    ataris = board.atari()
    deferredes = []
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            p = [x, y]
            $intersection = $(".intersection:nth-child(#{1 + p[0] + p[1] * BOARD_SIZE})")
            place = (blackOrWhite, beat) ->
                if effect and ((not $intersection.hasClass blackOrWhite) or ($intersection.hasClass 'half-opacity'))
                    deferred = $.Deferred()
                    deferredes.push deferred
                    $intersection.one $s.vendor.animationend, ->
                        $this = $(this)
                        $this.removeClass 'shake'
                        if beat
                            $this.addClass 'beat'
                        else
                            $this.removeClass 'beat'
                        deferred.resolve()
                    $intersection.removeClass('half-opacity').addClass "#{blackOrWhite} shake"
                else
                    $intersection.removeClass('black white half-opacity').addClass blackOrWhite
                    if beat
                        $intersection.addClass 'beat'
                    else
                        $intersection.removeClass 'beat'
            if blacks.some((e) -> e.isEqualTo p)
                place 'black', ataris.some (e) -> e.isEqualTo p
            else if whites.some((e) -> e.isEqualTo p)
                place 'white', ataris.some (e) -> e.isEqualTo p
            else
                if effect and ($intersection.hasClass('black') or ($intersection.hasClass 'white'))
                    deferred = $.Deferred()
                    deferredes.push deferred
                    $intersection.removeClass 'beat'
                    $intersection.one $s.vendor.transitionend, ((deferred) ->
                        ->
                            $(this).removeClass 'black white rise'
                            deferred.resolve()
                    )(deferred)
                    setTimeout (($intersection) -> -> $intersection.addClass 'rise')($intersection), 0 # beatを取ってからすぐriseを入れるとtransitionが起こらない。
                else
                    $intersection.removeClass 'white black half-opacity beat'
    $.when.apply(window, deferredes).done callback if effect


openAndCloseModal = (id, callback = ->) ->
    ###
    モーダルを一定時間表示する。
    ###
    $("##{id}").modal 'show'
    setTimeout (->
        $("##{id}").modal 'hide'
        callback()
    ), responseInterval
