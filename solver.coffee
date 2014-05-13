###
main for solver.html
###
# 四路の碁(仮名)
# (C) 2013 ICHIKAWA, Yuji (New 3 Rs)

evaluatedResult = null


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


editBoard = ->
    $('#black, #white').removeAttr 'disabled'
    $('.intersection').on 'click', ->
        $this = $(this)
        stone = $('#black-white > .active').attr 'id'
        if $this.hasClass stone
            $this.removeClass stone
        else
            $this.removeClass 'black white'
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
            if history[index].isEqualTo history[index - 1]
                openAndCloseModal if index % 2 then 'black-pass' else 'white-pass'
            else
                showOnBoard history[index], true
            if index < history.length - 1
                aux index + 1
            else
                $('#sequence').removeAttr 'disabled'
        ), 2000
    showOnBoard history[0]
    aux 1


$(document.body).on 'touchmove', (e) -> e.preventDefault() if window.Touch

$('#reset').on 'click', -> $('.intersection').removeClass 'black white'

$('#solve').on 'click', ->
    stopEditing()
    openAndCloseModal 'start-modal', ->
        wEvaluate [boardOnScreen()], BLACK, ((result) ->
            evaluatedResult = result
            cancelMessage()
            alert if result.value > 0 then "黒#{result.value}目勝ちですね" else if result.value < 0 then "白#{- result.value}目勝ちですね" else '引き分けですね'
            $('#sequence').removeAttr 'disabled'
            editBoard()
        ), ((error) ->
            if error.message is 'timeout'
                alert '降参…'
            else
                alert error.message
        ), 120000
        scheduleMessage()

$('#sequence').on 'click', ->
    $(this).attr 'disabled', 'disabled'
    playSequence evaluatedResult.history

showOnBoard OnBoard.fromString '''
     XOO
     O O
    XXOO
       O
    '''
editBoard()
