###
# 四路の碁(仮名)
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)
###

evaluatedResult = null
currentIndex = 0
responseInterval = 2000

window.printExpected = ->
    # 最初からの手順と読み筋を表示する
    # デバッグ用関数
    console.log expected.history.map((e)->e.toString()).join('\n')
    console.log expected.value


bgm =
    element: $('#bgm')[0]
    state: 'stop'
    play: ->
        bgm.element.play()
        bgm.state = 'play'
    pause: ->
        bgm.element.pause()
        bgm.state = 'pause'
    stop: ->
        bgm.element.pause()
        bgm.state = 'stop'
        try
            bgm.element.currentTime = 0 # iOS Safariでは再生前のavのcurrentTimeに代入しようとすると例外が発生する。
        catch e
            console.log e

window.onpagehide = -> bgm.pause() if bgm.state is 'play'

window.onpageshow = -> bgm.play() if bgm.state is 'pause'


evaluate = (history, next, success, error, timeout = 10000) ->
    # (web workerを使って)局面を評価する。
    # success, errorはコールバック関数。
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
    # boardの状態を描画する。
    # boardがnullなら空の盤。
    # effectをtrueにすると、今の状態からエフェクト入りで盤を変更
    if not board?
        $('.intersection').removeClass 'black white half-opacity'
        return

    [blacks, whites] = board.deployment()
    deferredes = []
    for x in [0...BOARD_SIZE]
        for y in [0...BOARD_SIZE]
            p = [x, y]
            $intersection = $(".intersection:nth-child(#{1 + p[0] + p[1] * BOARD_SIZE})")
            place = (blackOrWhite) ->
                if effect and ((not $intersection.hasClass blackOrWhite) or ($intersection.hasClass 'half-opacity'))
                    deferred = $.Deferred()
                    deferredes.push deferred
                    $intersection.one $s.vendor.animationend, ->
                        $(this).removeClass 'shake'
                        deferred.resolve()
                    $intersection.removeClass('half-opacity').addClass "#{blackOrWhite} shake"
                else
                    $intersection.removeClass('white half-opacity').addClass blackOrWhite
            if blacks.some((e) -> e.isEqualTo p)
                place 'black'
            else if whites.some((e) -> e.isEqualTo p)
                place 'white'
            else
                if effect and ($intersection.hasClass('black') or ($intersection.hasClass 'white'))
                    deferred = $.Deferred()
                    deferredes.push deferred
                    $intersection.one $s.vendor.transitionend, ((deferred) ->
                        ->
                            $(this).removeClass 'black white rise'
                            deferred.resolve()
                    )(deferred)
                    $intersection.addClass 'rise'
                else
                    $intersection.removeClass 'white black half-opacity'
    $.when.apply(window, deferredes).done callback if effect

boardOnScreen = ->
    blacks = []
    whites = []
    $('.intersection').each (i, e) ->
        $e = $(e)
        if $e.hasClass 'black'
            blacks.push [i % BOARD_SIZE, Math.floor(i / BOARD_SIZE)]
        else if $e.hasClass 'white'
            whites.push [i % BOARD_SIZE, Math.floor(i / BOARD_SIZE)]
    new OnBoard blacks, whites

endGame = ->
    bgm.stop()
    score = expected.value - expected.history[0].score()
    alert if score == 0
            '引き分け'
        else if score > 0
            "黒#{score}目勝ち"
        else
            "白#{-score}目勝ち"
    $('#start-stop').removeAttr 'disabled'


openAndCloseModal = (id, callback = ->) ->
    $("##{id}").modal 'show'
    setTimeout (->
        $("##{id}").modal 'hide'
        callback()
    ), responseInterval

editBoard = ->
    $('#black, #white').removeAttr 'disabled'
    $('.intersection').on 'click', ->
        $this = $(this)
        stone = $('#black-white > .active').attr 'id'
        if $this.hasClass stone
            $this.removeClass stone
        else
            $this.addClass stone

stopEditing = ->
    $('.intersection').off 'click'
    $('#black, #white').attr 'disabled', 'disabled'

scheduleMessage = ->
    messages = [
        interval: 10000
        id: 'babble-modal1'
    ,
        interval: 20000
        id: 'babble-modal2'
    ,
        interval: 30000
        id: 'babble-modal3'
    ,
        interval: 30000
        id: 'babble-modal4'
    ]
    aux = (index) ->
        scheduleMessage.id = setTimeout (->
            openAndCloseModal messages[index].id
            aux index + 1 if index < messages.length - 1
        ), messages[index].interval
    aux 0

cancelMessage = -> clearTimeout scheduleMessage.id

playSequence = (history) ->
    aux = (index) ->
        setTimeout (->
            showOnBoard history[index], true
            aux index + 1 if index < history.length - 1
        ), 2000
    showOnBoard history[0]
    aux 1

$(document.body).on 'touchmove', (e) -> e.preventDefault() if window.Touch

$('#solve').on 'click', ->
    stopEditing()
    openAndCloseModal 'start-modal', ->
        evaluate [boardOnScreen()], BLACK, ((result) ->
            evaluatedResult = result
            cancelMessage()
            alert if result.value > 0 then "黒#{result.value}目勝ちですね" else if result.value < 0 then "白#{result.value}目勝ちですね" else '引き分けですね'
            $('#sequence').removeAttr 'disabled'
            editBoard()
        ), ((error) ->
            if error.message is 'timeout'
                alert 'ギブアップ…'
            else
                alert error.message
        ), 120000
        scheduleMessage()

$('#sequence').on 'click', -> playSequence evaluatedResult.history

editBoard()
