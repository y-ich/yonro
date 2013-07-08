comparePosition = (a, b) ->
    dx = a[0] - b[0]
    if dx != 0 then dx else a[1] - b[1]

describe "OnBoard", ->
    describe "constructors", ->
        it "should return OnBoard instance", ->
            board = OnBoard.random()
            expect(board).toEqual jasmine.any OnBoard
        it "should return OnBoard instance", ->
            str = '''
                X O 
                 O X
                X O 
                 O X

                '''
            board = OnBoard.fromString str
            str0 = board.toString()
            console.log (str0.charCodeAt i for i in [0...str0.length]).join(',')
            console.log (str.charCodeAt i for i in [0...str.length]).join(',')
            expect(board.toString()).toEqual str
    describe "toString", ->
        it "should return ", ->
            board = new OnBoard [[1,1]], [[2,2]]
            expect(board.toString()).toBe '    \n X  \n  O \n    \n'
    describe "stringAndLibertyAt", ->
        it "", ->
            board = new OnBoard [[0,1], [1, 0], [1, 1]], []
            expect(board.stringAndLibertyAt([0,1]).map (e) -> e.sort comparePosition).toEqual [[[0,1], [1, 0], [1, 1]],[[0, 0], [2, 0], [2, 1], [1, 2],[0, 2]]].map (e) -> e.sort comparePosition

    describe "whoseEyeAt", ->
        it "should returns BLACK", ->
            board = new OnBoard [[0,1], [1, 0], [1, 1]], []
            expect(board.whoseEyeAt [0,0]).toBe BLACK
        it "should returns null", ->
            board = new OnBoard [[0,1], [1, 0]], []
            expect(board.whoseEyeAt [0,0]).toBe null
        it "should returns BLACK", ->
            board = new OnBoard [[1,0], [2, 0], [3, 1], [3, 2], [1, 3], [2, 3], [0, 1], [0, 2]], []
            expect(board.whoseEyeAt [0,0]).toBe BLACK
        it "should returns null", ->
            board = new OnBoard [[1,0], [2, 0], [3, 1], [3, 2], [1, 3], [2, 3]], []
            expect(board.whoseEyeAt [0,0]).toBe null

    describe "candidates", ->
        it "should returns candidates", ->
            board = OnBoard.random()
            candidates = board.candidates BLACK
            expect(candidates).toEqual jasmine.any Array

        it "should returns 14", ->
            board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[0,1],[2,1],[2,2],[0,3],[1,3],[2,3],[3,3]], []
            console.log board.toString()
            candidates = board.candidates BLACK
            console.log candidates
            expect(candidates).toEqual jasmine.any Array

    describe "eyes", ->
        it "should returns 14", ->
            board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[2,1],[1,2],[2,2],[3,2],[2,3],[3,3]], []
            console.log board.toString()
            expect(board.eyes()[0].length).toEqual 1
    describe "evaluate", ->
        it "両方活きの終局。0を返す", ->
            board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[1,3]], [[3,0],[2,0],[2,1],[2,2],[3,2],[2,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 0
        it "両方アタリで黒番。14を返す", ->
            board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[0,3],[1,3]], [[3,0],[2,0],[2,1],[2,2],[2,3],[3,2],[3,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 14
        it "両方アタリで白番。-14を返す", ->
            board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[0,3],[1,3]], [[3,0],[2,0],[2,1],[2,2],[2,3],[3,2],[3,3]]
            console.log board.toString()
            result = evaluate [board], WHITE
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value).toBe -14
        it "コウで黒番。14を返す", ->
            board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[0,3]], [[3,0],[2,0],[2,1],[2,2],[3,2],[1,3],[3,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 14
        it "セキ。1を返す", ->
            board = new OnBoard [[0,0],[1,0],[1,1],[1,2],[0,2],[0,3],[1,3]], [[3,0],[2,0],[2,1],[2,2],[3,2],[3,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 1
        it "should returns 14", ->
            board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[0,1],[2,1],[2,2],[0,3],[1,3],[2,3],[3,3]], []
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 14
        it "should returns 14", ->
            board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[0,1],[2,1],[2,2],[1,3],[2,3],[3,3]], [[1,1],[3,1],[0,2],[1,2]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 14
        it "should returns 14", ->
            board = new OnBoard [[0,0],[0,1],[0,2],[0,3],[1,0],[1,1],[1,2],[1,3],[2,1],[3,1],[3,3],[3,2],[2,3]], [[3,0]]
            console.log board.toString()
            expect(evaluate([board], WHITE).value).toBe 14
        it "should returns 14", ->
            board = new OnBoard [[0,0],[0,1],[0,2],[0,3],[1,0],[1,1],[1,2],[1,3],[2,1],[3,1],[3,3]], [[3,0]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 14
        it "should returns 14", ->
            board = new OnBoard [[0,0],[1,0],[0,1],[1,1],[2,1],[3,1],[0,2],[1,2],[0,3],[1,3]], [[2,0]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 14
        it "should returns 14", ->
            board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[3,2],[2,1],[0,2],[2,2],[2,3],[0,3],[3,3]], [[0,1],[1,1],[1,2]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 14
        it "should returns 5", ->
            board = new OnBoard [[0,0],[1,0],[2,0],[3,0],[2,2],[2,3],[3,3]], [[1,1],[3,1],[0,2],[1,2]]
            expect(evaluate([board], BLACK).value).toBe 5
        it "should returns -14", ->
            board = new OnBoard [[0,0]], [[3,0],[1,1],[2,1],[3,1],[0,2],[1,2],[2,2],[3,2],[0,3],[1,3],[2,3],[3,3]]
            console.log board.toString()
            expect(evaluate([board], WHITE).value).toBe -14
        it "should returns ", ->
            board = new OnBoard [[2,0],[0,1],[1,1],[2,3]], [[0,0]]
            console.log board.toString()
            expect(evaluate([board], WHITE).value).toBe 14
        it "should returns -5", ->
            board = new OnBoard [[2,0],[0,1],[1,1]], [[0,0],[3,0],[3,1],[0,2],[1,2],[2,2],[3,2],[0,3],[1,3],[3,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe -5
        it "should returns ", ->
            board = new OnBoard [], [[3,1],[0,2],[1,2],[3,2],[0,3],[1,3],[2,3],[3,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe -14
        it "should returns ", ->
            blacks = [[1,0],[0,1],[0,2],[1,2]]
            whites = [[2,0],[3,0],[1,1],[3,1],[2,2],[3,2],[3,3]]
            board = new OnBoard blacks, whites
            console.log board.toString()
            result = evaluate [board], WHITE
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value - (blacks.length - whites.length)).toBeGreaterThan 0
        # 黒猫のヨンロ
        it "should returns ", ->
            blacks = [[1,2],[2,2],[2,3]]
            whites = [[1,0],[3,0],[1,1],[3,1],[0,2],[3,2],[3,3]]
            board = new OnBoard blacks, whites
            console.log board.toString()
            result = evaluate [board], BLACK
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value - (blacks.length - whites.length)).toBeGreaterThan 0
        it "should returns ", ->
            blacks = [[0,0],[1,0],[2,0],[3,0],[1,2]]
            whites = [[0,2],[3,2],[0,3],[1,3],[2,3],[3,3]]
            board = new OnBoard blacks, whites
            console.log board.toString()
            result = evaluate [board], BLACK
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value - (blacks.length - whites.length)).toBeGreaterThan 0
        it "should returns ", ->
            blacks = [[2,2]]
            whites = [[1,0],[3,0],[0,1],[1,1],[0,2],[0,3],[1,3],[3,3]]
            board = new OnBoard blacks, whites
            console.log board.toString()
            result = evaluate [board], BLACK
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value - (blacks.length - whites.length)).toBeGreaterThan 0
        it "should returns ", ->
            blacks = [[1,0],[2,0],[2,1]]
            whites = [[3,0],[0,1],[1,1],[3,2],[0,3],[1,3],[3,3]]
            board = new OnBoard blacks, whites
            console.log board.toString()
            result = evaluate [board], BLACK
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value - (blacks.length - whites.length)).toBeGreaterThan 0
        it "should returns ", ->
            blacks = [[0,0],[2,0],[1,1],[2,2]]
            whites = [[3,0],[0,1],[3,1],[0,2],[1,2],[3,2],[2,3],[3,3]]
            board = new OnBoard blacks, whites
            console.log board.toString()
            result = evaluate [board], BLACK
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value - (blacks.length - whites.length)).toBeGreaterThan 0
        it "should returns ", ->
            blacks = [[1,0],[0,2],[1,2]]
            whites = [[2,0],[3,0],[1,1],[3,1],[2,2],[3,2],[3,3]]
            board = new OnBoard blacks, whites
            console.log board.toString()
            result = evaluate [board], BLACK
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value - (blacks.length - whites.length)).toBeGreaterThan 0
        it "should returns ", ->
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
            expect(result.history[2].isEqualTo board1).toBe true
        ###
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
            expect(result.value).toBe 3
        it "should returns ", ->
            board = new OnBoard [[2,0],[1,1],[1,2],[3,1]], [[2,1],[0,2],[2,2],[1,3]]
            console.log board.toString()
            result = evaluate [board], BLACK
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value).toBe 2
        it "should returns ", ->
            board = new OnBoard [[1,0],[1,1],[1,2],[0,3]], [[0,0],[2,0],[1,3],[2,2],[3,3]]
            console.log board.toString()
            result = evaluate [board], BLACK
            console.log result.history.map((e) -> e.toString()).join('\n')
            expect(result.value).toBe 14
        it "should returns ", ->
            board = new OnBoard [[0,0],[0,1],[1,2],[1,3],[2,3]], [[2,0],[2,1],[0,3],[3,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 14
        it "should returns ", ->
            board = new OnBoard [[2,0],[1,1],[1,2]], [[2,1],[2,2],[1,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 0
        it "should returns ", ->
            board = new OnBoard [[1,0],[1,1],[1,2]], [[2,1],[2,2],[2,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 0
        it "should returns ", ->
            board = new OnBoard [[2,0],[1,1],[1,2]], [[2,1],[2,2],[1,3]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 0
        it "should returns ", ->
            board = new OnBoard [[1,1],[1,2]], [[2,1],[2,2]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 0
        it "should returns ", -> # 100手で読めず。
            board = new OnBoard [[1,1]], [[2,2]]
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 0
        it "should returns ", ->
            board = new OnBoard [], []
            console.log board.toString()
            expect(evaluate([board], BLACK).value).toBe 0
        it "should returns number", ->
            board = OnBoard.random()
            console.log board.toString()
            score = evaluate([board], BLACK).value
            console.log score
            expect(score).toEqual jasmine.any Number
        ###