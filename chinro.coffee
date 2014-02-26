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
        ), 100
    showOnBoard history[0]
    aux 1


$(document.body).on 'touchmove', (e) -> e.preventDefault() if window.Touch

$('#reset').on 'click', -> $('.intersection').removeClass 'black white'

startSolve = (board, target)->
    openAndCloseModal 'start-modal', ->
        evaluatedResult = chaseShicho board, target
        alert if evaluatedResult.value then "取れました！" else "取れません…"
        $('#sequence').removeAttr 'disabled'
        editBoard()

$('#solve').on 'click', ->
    stopEditing()
    board = boardOnScreen()
    ps = checkTarget board
    if ps.length == 0
        alert 'アタリの石を作ってください'
        editBoard()
    else if ps.length == 1
        startSolve board, ps[0][0][0]
    else
        openAndCloseModal 'target-modal', ->
            $('.intersection').on 'click', ->
                $('.intersection').off 'click'
                index = $('.intersection').index this
                startSolve board, [index % BOARD_SIZE, Math.floor index / BOARD_SIZE]

$('#sequence').on 'click', ->
    $(this).attr 'disabled', 'disabled'
    playSequence evaluatedResult.history

setBoardSize 19

# 中山典之「ハート」
showOnBoard new OnBoard [[5,1],[6,1],[12,1],[13,1],[9,5],[1,6],[1,7],[17,8],[17,9],[7,15],[8,15],[9,16],[9,17]]
    ,[[5,0],[6,0],[12,0],[13,0],[9,2],[0,5],[8,5],[18,5],[0,6],[18,6],[0,7],[18,7],[0,8],[18,8],[0,9],[18,9],[9,14],[9,15],[8,16],[8,17],[10,17],[9,18]]

###
# 浦壁和彦「鬼ごっこ」
showOnBoard new OnBoard [[1,9],[2,8],[2,9],[2,10],[5,9],[7,9],[8,2],[8,8],[8,18],[9,1],[9,2],[9,5],[9,7],[9,8],[9,16],[9,17],[10,2],[10,16],[11,9],[12,10],[12,13],[12,14],[12,16],[12,17],[13,9],[13,13],[16,8],[16,9],[16,10],[17,9]]
    ,[[0,7],[0,9],[0,11],[1,6],[1,8],[1,10],[1,12],[2,5],[2,13],[3,4],[3,9],[3,14],[4,3],[4,9],[4,15],[5,2],[5,16],[6,1],[6,9],[6,17],[7,0],[7,8],[7,18],[8,1],[8,7],[9,0],[9,3],[9,4],[9,6],[9,9],[10,1],[10,7],[10,8],[10,9],[10,15],[10,17],[11,0],[11,14],[11,16],[11,18],[12,1],[12,11],[12,15],[12,18],[13,2],[13,14],[13,16],[13,17],[14,3],[14,9],[14,15],[15,4],[15,9],[15,14],[16,5],[16,13],[17,6],[17,8],[17,10],[17,12],[18,7],[18,9],[18,11]]
###

editBoard()

$('#opening-modal').modal 'show'
