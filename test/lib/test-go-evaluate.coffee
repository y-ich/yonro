assert = require 'assert'
{ BLACK, WHITE, MAX_SCORE, boardsToString } = require "../../go-common.coffee"
{ compare, evaluate } = require '../../go-evaluate.coffee'

testEvaluate = (kernel) ->
    ->
        { OnBoard } = require "../../#{kernel}.coffee"
        describe.skip 'compare', ->
            it 'should return positive', ->
                board1 = OnBoard.fromString '''
                    XXXX
                     OXO
                    OOX 
                      XX
                    '''
                board2 = OnBoard.fromString '''
                    XXXX
                     O O
                    OOX 
                     XXX
                    '''
                assert.equal compare(board1, board2, BLACK) > 0, true

        describe 'compare', ->
            it 'should return positive', ->
                board1 = OnBoard.fromString '''
                    XXXX
                     OOO
                    OO  
                    O OO
                    '''
                board2 = OnBoard.fromString '''
                    XXXX
                     OOO
                    OOXX
                    OOO 
                    '''
                assert.equal compare(board1, board2, WHITE) > 0, true

        describe "evaluate", ->
            it "両方活きの終局。0を返す", ->
                board = OnBoard.fromString """
                    XXOO
                     XO 
                    XXOO
                     XO 
                    """
                assert.equal evaluate([board], BLACK).value, 0
            it "両方アタリで黒番。MAX_SCOREを返す", ->
                board = OnBoard.fromString """
                    XXOO
                     XO 
                    XXOO
                    XXOO
                    """
                assert.equal evaluate([board], BLACK).value, MAX_SCORE
            it "両方アタリで白番。-MAX_SCOREを返す", ->
                board = OnBoard.fromString """
                    XXOO
                     XO 
                    XXOO
                    XXOO
                    """
                assert.equal evaluate([board], WHITE).value, -MAX_SCORE
            it "コウで黒番。MAX_SCOREを返す", ->
                board = OnBoard.fromString """
                    XXOO
                     XO 
                    XXOO
                    XO O
                    """
                assert.equal evaluate([board], BLACK).value, MAX_SCORE
            it "セキ。1を返す", ->
                board = OnBoard.fromString """
                    XXOO
                     XO 
                    XXOO
                    XX O
                    """
                assert.equal evaluate([board], BLACK).value, 1
            it "黒全滅", ->
                board = OnBoard.fromString """
                    XXXX
                     OOO
                    OOX 
                    XXXX
                    """
                result = evaluate [board], BLACK
                assert.equal result.value, -MAX_SCORE
            it "should returns 5", ->
                board = OnBoard.fromString """
                    XXXX
                     O O
                    OOX 
                      XX
                    """
                result = evaluate [board], BLACK
                assert.equal result.value, 5
            it "should returns -MAX_SCORE", ->
                board = OnBoard.fromString """
                    X  O
                     OOO
                    OOOO
                    OOOO
                    """
                result = evaluate [board], WHITE
                assert.equal result.value, -MAX_SCORE
            it "should returns ", ->
                board = OnBoard.fromString """
                    O X 
                    XX  
                        
                      X 
                    """
                assert.equal evaluate([board], WHITE).value, MAX_SCORE
            it "should returns -5", ->
                board = OnBoard.fromString """
                    O XO
                    XX O
                    OOOO
                    OO O
                    """
                assert.equal evaluate([board], BLACK).value, -5
            it "should returns ", ->
                board = OnBoard.fromString """
                     XOO
                    XO O
                    XXOO
                       O
                    """
                assert.equal evaluate([board], WHITE).value - (board.numOf(BLACK) - board.numOf(WHITE)) > 0, true
            it "セキ", ->
                board = OnBoard.fromString """
                    X XX
                     XOX
                    OXOX
                    OOO 
                    """
                result = evaluate [board], WHITE
                assert.equal result.value, 2

            it "黒猫のヨンロ1", ->
                board = OnBoard.fromString """
                     O O
                     O O
                    OXXO
                      XO
                    """
                assert.equal evaluate([board], BLACK).value - (board.numOf(BLACK) - board.numOf(WHITE)) > 0, true
            it "黒猫のヨンロ2", ->
                board = OnBoard.fromString """
                    XXXX
                
                    OX O
                    OOOO
                    """
                result = evaluate([board], BLACK)
                assert.equal result.value - (board.numOf(BLACK) - board.numOf(WHITE)) > 0, true
            it "黒猫のヨンロ3", ->
                board = OnBoard.fromString """
                     O O
                    OO  
                    O X 
                    OO O
                    """
                result = evaluate([board], BLACK)
                assert.equal result.value - (board.numOf(BLACK) - board.numOf(WHITE)) > 0, true
            it "黒猫のヨンロ4", ->
                board = OnBoard.fromString """
                     XXO
                    OOX 
                       O
                    OO O
                    """
                assert.equal evaluate([board], BLACK).value - (board.numOf(BLACK) - board.numOf(WHITE)) > 0, true
            it "黒猫のヨンロ5", ->
                board = OnBoard.fromString """
                    X XO
                    OX O
                    OOXO
                      OO
                    """
                assert.equal evaluate([board], BLACK).value - (board.numOf(BLACK) - board.numOf(WHITE)) > 0, true
            it "黒猫のヨンロ6", ->
                board = OnBoard.fromString """
                     XOO
                     O O
                    XXOO
                       O
                    """
                assert.equal evaluate([board], BLACK).value - (board.numOf(BLACK) - board.numOf(WHITE)) > 0, true
            it "黒猫のヨンロ7", ->
                board = OnBoard.fromString " XX \n XO \n XO \n OO "
                assert.equal evaluate([board], BLACK).value, 1
            it "メモ化の際のバグ確認", ->
                board0 = OnBoard.fromString """
                     XO 
                    XXO 
                     XO 
                     O O
                    """
                board1 = OnBoard.fromString """
                     XO 
                    XXOX
                     XO 
                     OOO
                    """
                result = evaluate [board0], BLACK
                result = evaluate result.history[0..1].concat(board1), WHITE
                assert.equal result.history[2].isEqualTo(board1), true
            # 長手数問題
            it "should returns ", ->
                board = OnBoard.fromString '''
                     XOX
                    XO X
                    X  O
                      OO
                    '''
                result = evaluate [board], BLACK
                assert.equal result.value, 4
            it "should returns ", ->
                board = OnBoard.fromString '''
                      X 
                     XOX
                    OXO 
                     O  
                    '''
                result = evaluate [board], BLACK
                assert.equal result.value, 2
            ###
            it "should returns ", ->
                board = new OnBoard [[1,0],[1,1],[1,2],[0,3]], [[0,0],[2,0],[1,3],[2,2],[3,3]]
                console.log '\n' + board.toString()
                result = evaluate [board], BLACK
                console.log result.history.map((e) -> e.toString()).join('\n')
                assert.equal result.value, MAX_SCORE
            it "should returns ", ->
                board = new OnBoard [[0,0],[0,1],[1,2],[1,3],[2,3]], [[2,0],[2,1],[0,3],[3,3]]
                console.log '\n' + board.toString()
                assert.equal evaluate([board], BLACK).value, MAX_SCORE
            it "should returns ", ->
                board = new OnBoard [[2,0],[1,1],[1,2]], [[2,1],[2,2],[1,3]]
                console.log '\n' + board.toString()
                assert.equal evaluate([board], BLACK).value, 0
            it "should returns ", ->
                board = new OnBoard [[1,0],[1,1],[1,2]], [[2,1],[2,2],[2,3]]
                console.log '\n' + board.toString()
                assert.equal evaluate([board], BLACK).value, 0
            it "should returns ", ->
                board = new OnBoard [[2,0],[1,1],[1,2]], [[2,1],[2,2],[1,3]]
                console.log '\n' + board.toString()
                assert.equal evaluate([board], BLACK).value, 0
            it "should returns ", ->
                board = new OnBoard [[1,1],[1,2]], [[2,1],[2,2]]
                console.log '\n' + board.toString()
                assert.equal evaluate([board], BLACK).value, 0
            it "should returns ", -> # 100手で読めず。
                board = new OnBoard [[1,1]], [[2,2]]
                console.log '\n' + board.toString()
                assert.equal evaluate([board], BLACK).value, 0
            it "should returns ", ->
                board = new OnBoard [], []
                console.log '\n' + board.toString()
                assert.equal evaluate([board], BLACK).value, 0
            ###

root = exports ? window
root.testEvaluate = testEvaluate
