assert = require 'assert'
{ countBits, BitBoardBase, OnBoard } = require '../bit-board.coffee'

BOARD_SIZE = 4
comparePosition = (a, b) ->
    dx = a[0] - b[0]
    if dx != 0 then dx else a[1] - b[1]

describe 'bit-board', ->
    base = new BitBoardBase BOARD_SIZE
    describe 'functions', ->
        describe 'countBits', ->
            it 'should return 0', ->
                assert.equal countBits(0), 0
            it 'should return 1', ->
                assert.equal countBits(2), 1
            it 'should return 2', ->
                assert.equal countBits(6), 2
    describe 'BitBoardBase', ->
        describe 'positionToBit', ->
            it 'should return 1', ->
                assert.equal base.positionToBit([0,0]), 0x01
        describe 'adjacent', ->
            it 'should return adjacent', ->
                p = base.positionToBit [0, 0]
                assert.equal base.adjacent(p, p), base.positionsToBits [[1, 0], [0, 1]]
        describe 'stringOf', ->
            it 'should return one stone', ->
                p = base.positionToBit [1, 1]
                assert.equal base.stringOf(p, p), p
            it 'should return one string', ->
                p = base.positionsToBits [[0, 1], [1, 0], [1,1]]
                assert.deepEqual base.stringOf(p, base.positionsToBits [[0, 1], [1, 0]]), p
        describe 'captured', ->
            it 'should return one stone', ->
                p = base.positionToBit [1, 1]
                assert.equal base.captured(p, base.adjacent(p, p)), p
        describe 'decomposeToStrings', ->
            it 'should return one string', ->
                p = base.positionsToBits [[0, 1], [1, 0], [1,1]]
                assert.deepEqual base.decomposeToStrings(base.stringOf p, base.positionsToBits [[0, 1], [1, 0]]), [p]
        describe 'interiorOf', ->
            it 'should return interior', ->
                interior = base.interiorOf base.positionsToBits [[2, 0], [3, 0], [2, 1], [3, 1], [2, 2], [3, 2], [2, 3], [3, 3]]
                assert.equal interior, base.positionsToBits [[3, 0], [3, 1], [3, 2], [3, 3]]

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
                str = '    \n X  \n  O \n    '
                board = new OnBoard.fromString str
                assert.equal board.toString(), str
        describe "stringAndLibertyAt", ->
            it "", ->
                board = new OnBoard base, [[0,1], [1, 0], [1, 1]], []
                assert.deepEqual board.stringAndLibertyAt([0,1]), [base.positionsToBits([[0,1], [1, 0], [1, 1]]), base.positionsToBits([[0, 0], [2, 0], [2, 1], [1, 2], [0, 2]])]
            it "", ->
                board = OnBoard.fromString """
                    XXXX
                    XOX 
                    OOXX
                    OXXX
                    """
                assert.equal board.stringAndLibertyAt([0,3])[1], 0

        describe "whoseEyeAt", ->
            it "should return BLACK", ->
                board = new OnBoard base, [[0,1], [1, 0], [1, 1]], []
                assert.equal board.whoseEyeAt([0,0]), board.base.BLACK
            it "should return null", ->
                board = new OnBoard base, [[0,1], [1, 0]], []
                assert.equal board.whoseEyeAt([0,0]), null
            it "should return BLACK", ->
                board = new OnBoard base, [[1,0], [2, 0], [3, 1], [3, 2], [1, 3], [2, 3], [0, 1], [0, 2]], []
                assert.equal board.whoseEyeAt([0,0]), board.base.BLACK
            it "should return BLACK", ->
                board = new OnBoard.fromString '''
                     XX 
                    XX X
                    OOOX
                    OXXX
                    '''
                assert.equal board.whoseEyeAt([2, 1]), board.base.BLACK
            it "should return null", ->
                board = OnBoard.fromString ' XX \n   X\n   X\n XX '
                assert.equal board.whoseEyeAt([0,0]), null
            it "should return black", ->
                board = OnBoard.fromString """
                    XXXX
                    X OX
                    O XX
                    XXXX
                    """
                assert.equal board.whoseEyeAt([1, 2]), board.base.BLACK
            it "should return no eyes", ->
                board = OnBoard.fromString """
                    XXXX
                     O O
                    OOX 
                     XXX
                    """
                assert.equal board.whoseEyeAt([0, 1]), null
        describe "candidates", ->
            it "should return candidates", ->
                board = OnBoard.random()
                candidates = board.candidates board.base.BLACK
                assert.ok candidates instanceof Array

            it "should return 14", ->
                board = new OnBoard base, [[0,0],[1,0],[2,0],[3,0],[0,1],[2,1],[2,2],[0,3],[1,3],[2,3],[3,3]], []
                candidates = board.candidates board.base.BLACK
                assert.ok candidates instanceof Array
            it "should return no candidates", ->
                board = OnBoard.fromString """
                    XXXX
                    XOX 
                    OOXX
                     XXX
                    """
                candidates = board.candidates board.base.WHITE
                assert.equal candidates.length, 0
            it "should return two candidates", ->
                board = OnBoard.fromString """
                    XXXX
                    X OX
                    O XX
                    XXXX
                    """
                candidates = board.candidates board.base.BLACK
                assert.equal candidates.length, 2

        describe "eyes", ->
            it "should return 2", ->
                board = OnBoard.fromString '''
                    XXXX
                      X 
                     XXX
                      XX
                    '''
                assert.equal board.eyes()[0].length, 1
            it "0", ->
                board = OnBoard.fromString """
                    X XX
                     XOX
                    OXOX
                    OOO 
                    """
                result = board.eyes()
                assert.equal result[0].length, 1
            it "0", ->
                board = OnBoard.fromString """
                     XXX
                    OXOX
                    OXOX
                    OOO 
                    """
                result = board.eyes()
                assert.equal result[0].length + result[1].length, 0

        describe "eyesOf", ->
            it "0", ->
                board = OnBoard.fromString """
                    XXXX
                     OOO
                    OOX 
                    XXXX
                    """
                result = board.eyesOf(board.base.WHITE)
                assert.equal result.length, 2

        describe "place", ->
            it "should return true", ->
                board = new OnBoard base, [], []
                assert.equal board.place(board.base.BLACK, [0,0]), true
            it "should return false", ->
                board = new OnBoard base, [[1,0],[0,1]], []
                assert.equal board.place(board.base.WHITE, [0,0]), false

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
        
        describe "isLegal", ->
            it "return false", ->
                board = OnBoard.fromString '''
                    OX  
                    X   
                        
                        
                    '''
                assert.equal board.isLegal(), false

        describe 'enclosedRegionOf', ->
            it "should return black enclosed region", ->
                board = OnBoard.fromString """
                    XXOO
                     XO 
                    XXOO
                     XO 
                    """
                region = board.enclosedRegionOf board.base.BLACK
                assert.equal region, base.positionsToBits [[0, 1], [0, 3]]

        describe 'closureAndRegionsOf', ->
            it "should return no candidates", ->
                board = OnBoard.fromString """
                    XXOO
                     XO 
                    XXOO
                     XO 
                    """
                closure = board.closureAndRegionsOf board.base.BLACK
                assert.equal closure, base.positionsToBits [[0, 0], [1, 0], [0, 1], [1, 1], [0, 2], [1, 2], [0, 3], [1, 3]]

    describe 'combination', ->
        it "should return", ->
            board = OnBoard.fromString '''
                 XX 
                XX X
                OOOX
                OXXX
                '''
            eyes = board.eyes()
            console.log eyes
            console.log board.numOfLiberties(board.base.WHITE)
            assert.equal eyes[0].length >= 2 and board.numOfLiberties(board.base.WHITE) <= 1, true
