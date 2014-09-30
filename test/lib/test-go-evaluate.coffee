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
            it 'should return positive', ->
                board1 = OnBoard.fromString '''
                    XXXX
                     OOO
                    OOXX
                    OOO 
                    '''
                board2 = OnBoard.fromString '''
                    XXXX
                     OOO
                    OO  
                    O OO
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
            it "should return 5", ->
                board = OnBoard.fromString """
                    XXXX
                     O O
                    OOX 
                      XX
                    """
                result = evaluate [board], BLACK
                assert.equal result.value, 5
            it "should return -MAX_SCORE", ->
                board = OnBoard.fromString """
                    X  O
                     OOO
                    OOOO
                    OOOO
                    """
                result = evaluate [board], WHITE
                assert.equal result.value, -MAX_SCORE
            it "should return -5", ->
                board = OnBoard.fromString """
                    O XO
                    XX O
                    OOOO
                    OO O
                    """
                assert.equal evaluate([board], BLACK).value, -5
            it "白先でも黒勝ち", -> # 15 depth 165065ms
                board = OnBoard.fromString """
                     XOO
                    XO O
                    XXOO
                       O
                    """
                assert.equal evaluate([board], WHITE).value - board.score() > 0, true
            it "セキ", ->
                board = OnBoard.fromString """
                    X XX
                     XOX
                    OXOX
                    OOO 
                    """
                result = evaluate [board], WHITE
                assert.equal result.value, 2
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
            it "1. should return ", ->
                board = OnBoard.fromString """
                    O X 
                    XX  
                        
                      X 
                    """
                assert.equal evaluate([board], WHITE).value, MAX_SCORE
            it "2. should return ", ->
                board = OnBoard.fromString '''
                     XOX
                    XO X
                    X  O
                      OO
                    '''
                result = evaluate [board], BLACK
                assert.equal result.value, 4
            it "4. should return ", ->
                board = OnBoard.fromString '''
                    OXO 
                     X  
                     XO 
                    XO O
                    '''
                result = evaluate [board], BLACK
                assert.equal result.value, MAX_SCORE
            it "5. should return ", ->
                board = OnBoard.fromString '''
                    X O 
                    X O 
                     X  
                    OXXO
                    '''
                assert.equal evaluate([board], BLACK).value, MAX_SCORE
            it "終局 ", ->
                board = OnBoard.fromString '''
                    OOOO
                    OOOO
                    OOO 
                      O 
                    '''
                assert.equal evaluate([board, board], WHITE).value, -MAX_SCORE
        describe.only '黒猫のヨンロ', ->
            it "1", ->
                board = OnBoard.fromString """
                     O O
                     O O
                    OXXO
                      XO
                    """
                assert.equal evaluate([board], BLACK).value - board.score() > 0, true
            it "2", ->
                board = OnBoard.fromString """
                    XXXX
                        
                    OX O
                    OOOO
                    """
                result = evaluate([board], BLACK)
                assert.equal result.value - board.score() > 0, true
            it "3", ->
                board = OnBoard.fromString """
                     O O
                    OO  
                    O X 
                    OO O
                    """
                result = evaluate([board], BLACK)
                assert.equal result.value - board.score() > 0, true
            it "4", ->
                board = OnBoard.fromString """
                     XXO
                    OOX 
                       O
                    OO O
                    """
                assert.equal evaluate([board], BLACK).value - board.score() > 0, true
            it "5", ->
                board = OnBoard.fromString """
                    X XO
                    OX O
                    OOXO
                      OO
                    """
                assert.equal evaluate([board], BLACK).value - board.score() > 0, true
            it "6", ->
                board = OnBoard.fromString """
                     XOO
                     O O
                    XXOO
                       O
                    """
                assert.equal evaluate([board], BLACK).value - board.score() > 0, true
            it "7", ->
                board = OnBoard.fromString " XX \n XO \n XO \n OO "
                assert.equal evaluate([board], BLACK).value, 1
        describe.skip "長手数問題", ->
            it "3. should return ", -> #解けない
                board = OnBoard.fromString '''
                      X 
                     XOX
                    OXO 
                     O  
                    '''
                result = evaluate [board], BLACK
                assert.equal result.value, 2
            it "6. should return ", -> #解けない
                board = OnBoard.fromString '  X \n XO \n XO \n O  '
                assert.equal evaluate([board], BLACK).value, 0
            it "7. should return ", ->
                board = OnBoard.fromString ' X  \n XO \n XO \n  O '
                assert.equal evaluate([board], BLACK).value, 0
            it "8. should return ", ->
                board = OnBoard.fromString ' X  \n XO \n XO \n O  '
                assert.equal evaluate([board], BLACK).value, 0
            it "9. should return ", ->
                board = OnBoard.fromString '    \n XO \n XO \n    '
                assert.equal evaluate([board], BLACK).value, 0
            it "10. should return ", -> # 100手で読めず。
                board = OnBoard.fromString '    \n X  \n  O \n    '
                assert.equal evaluate([board], BLACK).value, 0
            it "11. should return ", ->
                board = new OnBoard [], []
                assert.equal evaluate([board], BLACK).value, MAX_SCORE

root = exports ? window
root.testEvaluate = testEvaluate
