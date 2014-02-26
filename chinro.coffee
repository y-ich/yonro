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
        console.log this
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
        ), 100
    showOnBoard history[0]
    aux 1


$(document.body).on 'touchmove', (e) -> e.preventDefault() if window.Touch

$('#reset').on 'click', -> $('.intersection').removeClass 'black white'

$('#solve').on 'click', ->
    stopEditing()
    openAndCloseModal 'start-modal', ->
        evaluatedResult = chaseShicho boardOnScreen()
        console.log evaluatedResult
        alert if evaluatedResult.value then "取れました！" else "取れません…"
        $('#sequence').removeAttr 'disabled'
        editBoard()

$('#sequence').on 'click', ->
    $(this).attr 'disabled', 'disabled'
    playSequence evaluatedResult.history

setBoardSize 19

showOnBoard new OnBoard [[5,1],[6,1],[12,1],[13,1],[9,5],[1,6],[1,7],[17,8],[17,9],[7,15],[8,15],[9,16],[9,17]]
    ,[[5,0],[6,0],[12,0],[13,0],[9,2],[0,5],[8,5],[18,5],[0,6],[18,6],[0,7],[18,7],[0,8],[18,8],[0,9],[18,9],[9,14],[9,15],[8,16],[8,17],[10,17],[9,18]]

editBoard()

$('#opening-modal').modal 'show'
