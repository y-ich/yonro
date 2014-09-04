assert = require 'assert'
{ BLACK, WHITE, EMPTY } = require '../go-common.coffee'
{ OnBoard } = require '../array-board.coffee'


comparePosition = (a, b) ->
    dx = a[0] - b[0]
    if dx != 0 then dx else a[1] - b[1]

describe 'array-board', ->
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
            it "should return a OnBoard instance", ->
                board = new OnBoard [[1,1]], [[2,2]]
                assert.equal board.toString(), '    \n X  \n  O \n    \n'
        describe "stringAndLibertyAt", ->
            it "should return string and liberty", ->
                board = new OnBoard [[0,1], [1, 0], [1, 1]], []
                assert.deepEqual board.stringAndLibertyAt([0,1]).map((e) -> e.sort comparePosition), [[[0,1], [1, 0], [1, 1]],[[0, 0], [2, 0], [2, 1], [1, 2],[0, 2]]].map (e) -> e.sort comparePosition

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

        describe "isEqualTo", ->
            it "should return true", ->
                board = OnBoard.fromString '''
                    X O 
                    OOOO
                    OO O
                    O   
                    '''
                assert.equal board.isEqualTo('''
                    X O 
                    OOOO
                    OO O
                    O   
                    '''), true
            
