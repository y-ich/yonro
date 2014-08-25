assert = require 'assert'
{ BLACK, WHITE, EMPTY, OnBoard, countBits, positionToBit, positionsToBits, adjacent, stringOf, captured, decomposeToStrings } = require '../bit-board.coffee'

describe 'functions ', ->
    describe 'countBits', ->
        it 'should return 0', ->
            assert.equal countBits(0), 0
        it 'should return 1', ->
            assert.equal countBits(2), 1
        it 'should return 2', ->
            assert.equal countBits(6), 2
    describe 'positionToBit', ->
        it 'should return 2', ->
            assert.equal positionToBit([0,0]), 0x02
    describe 'adjacent', ->
        it 'should return 2', ->
            p = positionToBit [0, 0]
            assert.equal adjacent(p, p), positionsToBits [[1, 0], [0, 1]]
    describe 'stringOf', ->
        it 'should return one stone', ->
            p = positionToBit [1, 1]
            assert.equal stringOf(p, p), p
        it 'should return one string', ->
            p = positionsToBits [[0, 1], [1, 0], [1,1]]
            assert.deepEqual stringOf(p, positionsToBits [[0, 1], [1, 0]]), p
    describe 'captured', ->
        it 'should return one stone', ->
            p = positionToBit [1, 1]
            assert.equal captured(p, adjacent(p, p)), p
    describe 'decomposeToStrings', ->
        it 'should return one string', ->
            p = positionsToBits [[0, 1], [1, 0], [1,1]]
            assert.deepEqual decomposeToStrings(stringOf p, positionsToBits [[0, 1], [1, 0]]), [p]

comparePosition = (a, b) ->
    dx = a[0] - b[0]
    if dx != 0 then dx else a[1] - b[1]

describe "OnBoard", ->
    describe "constructors", ->
        it "should return OnBoard instance", ->
            str = '''
                X O 
                 O X
                X O 
                 O X

                '''
            board = OnBoard.fromString str
            str0 = board.toString()
            assert.equal board.toString(), str
    describe "toString", ->
        it "should return ", ->
            board = new OnBoard [[1,1]], [[2,2]]
            assert.equal board.toString(), '    \n X  \n  O \n    \n'
    describe "stringAndLibertyAt", ->
        it "", ->
            board = new OnBoard [[0,1], [1, 0], [1, 1]], []
            assert.deepEqual board.stringAndLibertyAt([0,1]), [positionsToBits([[0,1], [1, 0], [1, 1]]), positionsToBits([[0, 0], [2, 0], [2, 1], [1, 2], [0, 2]])]

    describe "whoseEyeAt", ->
        it "should returns BLACK", ->
            board = new OnBoard [[0,1], [1, 0], [1, 1]], []
            assert.equal board.whoseEyeAt([0,0]), BLACK
        it "should returns null", ->
            board = new OnBoard [[0,1], [1, 0]], []
            assert.equal board.whoseEyeAt([0,0]), null
        it "should returns BLACK", ->
            board = new OnBoard [[1,0], [2, 0], [3, 1], [3, 2], [1, 3], [2, 3], [0, 1], [0, 2]], []
            assert.equal board.whoseEyeAt([0,0]), BLACK
        it "should returns null", ->
            board = new OnBoard [[1,0], [2, 0], [3, 1], [3, 2], [1, 3], [2, 3]], []
            assert.equal board.whoseEyeAt([0,0]), null

    describe "candidates", ->
        it "should returns candidates", ->
            board = OnBoard.random()
            candidates = board.candidates BLACK
            assert.ok candidates instanceof Array

        it "should returns 14", ->
            board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[0,1],[2,1],[2,2],[0,3],[1,3],[2,3],[3,3]], []
            candidates = board.candidates BLACK
            assert.ok candidates instanceof Array

    describe "eyes", ->
        it "should returns 14", ->
            board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[2,1],[1,2],[2,2],[3,2],[2,3],[3,3]], []
            assert.equal board.eyes()[0].length, 1
