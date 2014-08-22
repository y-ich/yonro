assert = require 'assert'

describe "evaluate", ->
    it "両方活きの終局。0を返す", ->
        board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[1,3]], [[3,0],[2,0],[2,1],[2,2],[3,2],[2,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 0
    it "両方アタリで黒番。14を返す", ->
        board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[0,3],[1,3]], [[3,0],[2,0],[2,1],[2,2],[2,3],[3,2],[3,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 14
    it "両方アタリで白番。-14を返す", ->
        board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[0,3],[1,3]], [[3,0],[2,0],[2,1],[2,2],[2,3],[3,2],[3,3]]
        console.log board.toString()
        result = evaluate [board], WHITE
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value, -14
    it "コウで黒番。14を返す", ->
        board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[0,3]], [[3,0],[2,0],[2,1],[2,2],[3,2],[1,3],[3,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 14
    it "セキ。1を返す", ->
        board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[0,3],[1,3]], [[3,0],[2,0],[2,1],[2,2],[3,2],[3,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 1
    it "should returns 14", ->
        board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[0,1],[2,1],[2,2],[0,3],[1,3],[2,3],[3,3]], []
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 14
    it "should returns 14", ->
        board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[0,1],[2,1],[2,2],[1,3],[2,3],[3,3]], [[1,1],[3,1],[0,2],[1,2]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 14
    it "should returns 14", ->
        board = new OnBoard [[0,0],[0,1],[0,2],[0,3],[1,0],[1,1],[1,2],[1,3],[2,1],[3,1],[3,3],[3,2],[2,3]], [[3,0]]
        console.log board.toString()
        expect(evaluate([board], WHITE).value).toBe 14
    it "should returns 14", ->
        board = new OnBoard [[0,0],[0,1],[0,2],[0,3],[1,0],[1,1],[1,2],[1,3],[2,1],[3,1],[3,3]], [[3,0]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 14
    it "should returns 14", ->
        board = new OnBoard [[0,0],[1,0],[0,1],[1,1],[2,1],[3,1],[0,2],[1,2],[0,3],[1,3]], [[2,0]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 14
    it "should returns 14", ->
        board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[3,2],[2,1],[0,2],[2,2],[2,3],[0,3],[3,3]], [[0,1],[1,1],[1,2]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 14
    it "should returns 5", ->
        board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[2,2],[2,3],[3,3]], [[1,1],[3,1],[0,2],[1,2]]
        assert.equal evaluate([board], BLACK).value, 5
    it "should returns -14", ->
        board = new OnBoard [[0,0]], [[3,0],[1,1],[2,1],[3,1],[0,2],[1,2],[2,2],[3,2],[0,3],[1,3],[2,3],[3,3]]
        console.log board.toString()
        assert.equal evaluate([board], WHITE).value, -14
    it "should returns ", ->
        board = new OnBoard [[2,0],[0,1],[1,1],[2,3]], [[0,0]]
        console.log board.toString()
        assert.equal evaluate([board], WHITE).value, 14
    it "should returns -5", ->
        board = new OnBoard [[2,0],[0,1],[1,1]], [[0,0],[3,0],[3,1],[0,2],[1,2],[2,2],[3,2],[0,3],[1,3],[3,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, -5
    it "should returns ", ->
        board = new OnBoard [], [[3,1],[0,2],[1,2],[3,2],[0,3],[1,3],[2,3],[3,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, -14
    it "should returns ", ->
        blacks = [[1,0],[0,1],[0,2],[1,2]]
        whites = [[2,0],[3,0],[1,1],[3,1],[2,2],[3,2],[3,3]]
        board = new OnBoard blacks, whites
        console.log board.toString()
        result = evaluate [board], WHITE
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value - (blacks.length - whites.length) > 0, true
    it "黒猫のヨンロ", ->
        blacks = [[1,2],[2,2],[2,3]]
        whites = [[1,0],[3,0],[1,1],[3,1],[0,2],[3,2],[3,3]]
        board = new OnBoard blacks, whites
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value - (blacks.length - whites.length) > 0, true
    it "黒猫のヨンロ", ->
        blacks = [[0,0],[1,0],[2,0],[3,0],[1,2]]
        whites = [[0,2],[3,2],[0,3],[1,3],[2,3],[3,3]]
        board = new OnBoard blacks, whites
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value - (blacks.length - whites.length) > 0, true
    it "黒猫のヨンロ", ->
        blacks = [[2,2]]
        whites = [[1,0],[3,0],[0,1],[1,1],[0,2],[0,3],[1,3],[3,3]]
        board = new OnBoard blacks, whites
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value - (blacks.length - whites.length) > 0, true
    it "黒猫のヨンロ", ->
        blacks = [[1,0],[2,0],[2,1]]
        whites = [[3,0],[0,1],[1,1],[3,2],[0,3],[1,3],[3,3]]
        board = new OnBoard blacks, whites
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value - (blacks.length - whites.length) > 0, true
    it "黒猫のヨンロ", ->
        blacks = [[0,0],[2,0],[1,1],[2,2]]
        whites = [[3,0],[0,1],[3,1],[0,2],[1,2],[3,2],[2,3],[3,3]]
        board = new OnBoard blacks, whites
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value - (blacks.length - whites.length) > 0, true
    it "黒猫のヨンロ", ->
        blacks = [[1,0],[0,2],[1,2]]
        whites = [[2,0],[3,0],[1,1],[3,1],[2,2],[3,2],[3,3]]
        board = new OnBoard blacks, whites
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value - (blacks.length - whites.length) > 0, true
    it "黒猫のヨンロ", ->
        board = new OnBoard [[1,0],[2,0],[1,1],[1,2]], [[2,1],[2,2],[1,3],[2,3]]
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        expect(result.value).toBe 1
    it "メモ化の際のバグ確認", ->
        board0 = new OnBoard [[1,0],[0,1],[1,1],[1,2]], [[2,0],[2,1],[2,2],[1,3],[3,3]]
        board1 = new OnBoard [[1,0],[0,1],[1,1],[1,2],[3,1]], [[2,0],[2,1],[2,2],[1,3],[2,3],[3,3]]
        result = evaluate [board0], BLACK
        result = evaluate result.history[0..1].concat(board1), WHITE
        console.log result.history[2].toString()
        assert.equal result.history[2].isEqualTo(board1), true
    # 長手数問題
    it "should returns ", ->
        board = OnBoard.fromString '''
             XOX
            XO X
            X  O
              OO
            '''
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value, 3
    it "should returns ", ->
        board = new OnBoard [[2,0],[1,1],[1,2],[3,1]], [[2,1],[0,2],[2,2],[1,3]]
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value, 2
    it "should returns ", ->
        board = new OnBoard [[1,0],[1,1],[1,2],[0,3]], [[0,0],[2,0],[1,3],[2,2],[3,3]]
        console.log board.toString()
        result = evaluate [board], BLACK
        console.log result.history.map((e) -> e.toString()).join('\n')
        assert.equal result.value, 14
    it "should returns ", ->
        board = new OnBoard [[0,0],[0,1],[1,2],[1,3],[2,3]], [[2,0],[2,1],[0,3],[3,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 14
    it "should returns ", ->
        board = new OnBoard [[2,0],[1,1],[1,2]], [[2,1],[2,2],[1,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 0
    it "should returns ", ->
        board = new OnBoard [[1,0],[1,1],[1,2]], [[2,1],[2,2],[2,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 0
    it "should returns ", ->
        board = new OnBoard [[2,0],[1,1],[1,2]], [[2,1],[2,2],[1,3]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 0
    it "should returns ", ->
        board = new OnBoard [[1,1],[1,2]], [[2,1],[2,2]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 0
    it "should returns ", -> # 100手で読めず。
        board = new OnBoard [[1,1]], [[2,2]]
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 0
    it "should returns ", ->
        board = new OnBoard [], []
        console.log board.toString()
        assert.equal evaluate([board], BLACK).value, 0
    it "should returns number", ->
        board = OnBoard.random()
        console.log board.toString()
        score = evaluate([board], BLACK).value
        console.log score
        assert.equal (typeof score), 'number'
