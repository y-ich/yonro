###
# 四路の碁(仮名)
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)
###

userStone = BLACK
expected = null
currentIndex = 0

if localStorage['yonro']?
    settings = JSON.parse localStorage['yonro']
    $('#music-off').prop 'checked', settings['music-off']

saveSettings = ->
    localStorage['yonro'] = JSON.stringify
        'music-off': $('#music-off').prop 'checked'

try
    document.createEvent("TouchEvent");
    if window.Touch? and (typeof window.ontouchstart) != 'undefined'
        touchDevice = true
    else false
catch
    touchDevice = false

window.printExpected = ->
    # 最初からの手順と読み筋を表示する
    # デバッグ用関数
    console.log expected.toString()

bgm =
    element: $('#bgm')[0]
    state: 'stop'
    play: ->
        return if $('#music-off').prop('checked')
        bgm.element.volume = 0.1
        bgm.element.play()
        bgm.state = 'play'
    pause: ->
        if bgm.state is 'play'
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

endGame = ->
    bgm.stop()
    score = expected.value
    alert if score == 0
            '引き分け'
        else if score > 0
            "黒#{score}目勝ち"
        else
            "白#{-score}目勝ち"
    $('#start-stop').removeAttr 'disabled'


computerPlay = (board) ->
    behaveNext = ->
        currentIndex += 1 # コンピュータの手
        if currentIndex < expected.history.length
            if board.isEqualTo expected.history[currentIndex]
                setTimeout (-> # behaveNextはwEvaluateのコールバックなのですぐに終了するようにタイマー処理。
                    alert 'パスします'
                    if (expected.history[currentIndex - 2]?.isEqualTo board) and (expected.history[currentIndex - 1]?.isEqualTo board)
                        # 相手もパスだったら
                        endGame()
                    else
                        waitForUserPlay()
                ), 0
            else
                showOnBoard expected.history[currentIndex], true, waitForUserPlay
        else
            endGame()

    if expected.history[currentIndex]?.isEqualTo board # 読み筋通りなら
        if expected.history.length - 1 > currentIndex # 続きがあれば
            if not expected.history[currentIndex - 1]?.isEqualTo board # パスでない
                score = expected.value
                score = if userStone is BLACK then -score else score
                if score > 0
                    openAndCloseModal 'expect-modal', behaveNext
                else if expected.value is (if userStone is BLACK then MAX_SCORE else -MAX_SCORE) and expected.history[expected.history.length - 1].numOf(opponentOf userStone) == 0
                    bgm.stop()
                    setTimeout (->
                        alert '負けました…'
                        $('#start-stop').removeAttr 'disabled'
                    ), responseInterval
                else if score < 0
                    openAndCloseModal 'pessimistic-modal', behaveNext
                else
                    setTimeout (->
                        behaveNext()
                    ), responseInterval
            else if expected.value is (if userStone is BLACK then MAX_SCORE else -MAX_SCORE) and expected.history[expected.history.length - 1].numOf(opponentOf userStone) == 0
                bgm.stop()
                setTimeout (->
                    alert '負けました…'
                    $('#start-stop').removeAttr 'disabled'
                ), responseInterval
            else
                setTimeout (->
                    behaveNext()
                ), responseInterval
        else if expected.value is (if userStone is BLACK then MAX_SCORE else -MAX_SCORE)
            bgm.stop()
            setTimeout (->
                alert '負けました…'
                $('#start-stop').removeAttr 'disabled'
            ), responseInterval
        else
            $('#unexpected-modal').modal 'show'
            wEvaluate expected.history[0...currentIndex].concat(board), opponentOf(userStone), ((result) ->
                expected = result
                if expected.value is (if userStone is BLACK then MAX_SCORE else -MAX_SCORE) and expected.history[expected.history.length - 1].numOf(opponentOf userStone) == 0
                    bgm.stop()
                    setTimeout (->
                        alert '負けました…'
                        $('#start-stop').removeAttr 'disabled'
                    ), responseInterval
                else
                    behaveNext()
            ),
            ((error) ->
                $('#evaluate-modal').modal 'hide'
                expected =
                    value: NaN
                    history: expected.history[0...currentIndex].concat(board)
                computerStone = opponentOf userStone
                candidates = board.candidates computerStone
                nodes = []
                for b in candidates
                    parity = if userStone is BLACK then 0 else 1
                    nodes.push b if expected.history.filter((e, i) -> (i % 2) == parity).every((e) -> not b.isEqualTo e)
                nodes.sort (a, b) -> - compare a, b, computerStone
                expected.history.push nodes[0]
                openAndCloseModal 'upset-modal', behaveNext
            )
    else
        wEvaluate expected.history[0...currentIndex].concat(board), opponentOf(userStone), ((result) ->
            expected = result
            behaveNext()
        ),
        ((error) ->
            expected =
                value: NaN
                history: expected.history[0...currentIndex].concat(board)
            computerStone = opponentOf userStone
            candidates = board.candidates computerStone
            nodes = []
            for b in candidates
                parity = if userStone is BLACK then 0 else 1
                nodes.push b if expected.history.filter((e, i) -> (i % 2) == parity).every((e) -> not b.isEqualTo e)
            nodes.sort (a, b) -> - compare a, b, computerStone
            expected.history.push nodes[0]
            behaveNext()
        )


userPlayAndResponse = (position) ->
    $('#pass, #resign').attr 'disabled', 'disabled'

    board = expected.history[currentIndex].copy()
    # if board.place userStone, position
    if board.place userStone, position
        parity = (currentIndex + 1) % 2
        if position? and expected.history[0...currentIndex].filter((e, i) -> (i % 2) == parity).some((e) -> board.isEqualTo e) # 循環
            alert 'そこへ打つと繰り返し…'
            showOnBoard expected.history[currentIndex]
            waitForUserPlay()
        else
            showOnBoard board, true, ->
                currentIndex += 1
                computerPlay board
    else
        alert 'そこは打てないよ〜'
        showOnBoard expected.history[currentIndex]
        waitForUserPlay()


$board = $('#board')
if touchDevice
    $(document.body).on 'touchmove', (e) -> e.preventDefault()
    waitForUserPlay = ->
        $board.on 'touchstart', '.intersection:not(.black):not(.white)', ->
            $board.off 'touchstart', '.intersection:not(.black):not(.white)'

            $(this).addClass "#{if userStone is BLACK then 'black' else 'white'} half-opacity"

            $board.on 'touchmove', (e) ->
                event = e.originalEvent
                $target = $(document.elementFromPoint event.touches[0].clientX, event.touches[0].clientY)
                if $target.is '.intersection:not(.black):not(.white)'
                    $target.parent().children('.half-opacity').removeClass 'black white half-opacity'
                    $target.addClass "#{if userStone is BLACK then 'black' else 'white'} half-opacity"

            $board.on 'touchend touchcancel', (e) ->
                $board.off 'touchmove touchend touchcancel'
                return if e.type is 'touchcancel'
                event = e.originalEvent
                $target = $(document.elementFromPoint event.changedTouches[0].clientX, event.changedTouches[0].clientY)
                if $target.is '.intersection.half-opacity'
                    index = $target.prevAll().length
                    userPlayAndResponse.call this, [index % BOARD_SIZE, Math.floor(index / BOARD_SIZE)]

        $('#pass, #resign').removeAttr 'disabled'
    cancelWaiting = ->
        $board.off 'touchstart', '.intersection:not(.black):not(.white)'
        $board.off 'touchmove touchend touchcancel'
else
    waitForUserPlay = ->
        $board.on 'mousedown', '.intersection:not(.black):not(.white)', ->
            $board.off 'mousedown', '.intersection:not(.black):not(.white)'

            $(this).addClass "#{if userStone is BLACK then 'black' else 'white'} half-opacity"

            $board.on 'mouseleave', '.intersection.half-opacity', ->
                $(this).removeClass 'black white half-opacity'

            $board.on 'mouseenter', '.intersection:not(.black):not(.white)', ->
                $(this).addClass "#{if userStone is BLACK then 'black' else 'white'} half-opacity"

            $board.on 'mouseup', '.intersection.half-opacity', ->
                $board.off 'mouseleave', '.intersection.half-opacity'
                $board.off 'mouseenter', '.intersection:not(.black):not(.white)'
                $board.off 'mouseup', '.intersection.half-opacity'

                index = $(this).prevAll().length
                userPlayAndResponse.call this, [index % BOARD_SIZE, Math.floor(index / BOARD_SIZE)]

        $('#pass, #resign').removeAttr 'disabled'
    cancelWaiting = ->
        $board.off 'mousedown', '.intersection:not(.black):not(.white)'
        $board.off 'mouseleave', '.intersection.half-opacity'
        $board.off 'mouseenter', '.intersection:not(.black):not(.white)'
        $board.off 'mouseup', '.intersection.half-opacity'

$('#start-stop').on 'click', ->
    showOnBoard null

    board = new OnBoard.random()
    expected =
        value: NaN
        history: [board]
    currentIndex = 0
    showOnBoard expected.history[currentIndex]
    setTimeout (-> $('#select-modal').modal 'show'), 3000

$('#play-white, #play-black').on 'click', ->
    $('#start-stop').attr 'disabled', 'disabled'
    userStone = switch @id
        when 'play-white' then WHITE
        when 'play-black' then BLACK
        else null
    bgm.play()
    openAndCloseModal 'start-modal', ->
        if userStone is BLACK
            waitForUserPlay()
        else
            computerPlay expected.history[currentIndex]

$('#pass').on 'click', ->
    cancelWaiting()
    userPlayAndResponse null # パス

$('#resign').on 'click', ->
    cancelWaiting()
    bgm.stop()
    openAndCloseModal 'end-modal', ->
        $('#start-stop').removeAttr 'disabled'
        $('#pass, #resign').attr 'disabled', 'disabled'

$('#music-off').on 'change', ->
    if $(this).prop('checked')
        bgm.pause()
    else if $('#start-stop').prop 'disabled'
        bgm.play()
    saveSettings()
