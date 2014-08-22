{spawn, exec} = require 'child_process'

bitBoardTest = ['tests/testBitBoard.coffee', 'bit-board.coffee']
goEvaluateTest = ['tests/test-go-evaluate.coffee', 'go-common.coffee', 'go-evaluate.coffee']

task 'app', 'build app', ->
    worker = spawn 'coffee', ['-wcj', 'go-worker.js', 'bit-board.coffee', 'go-evaluate.coffee', 'go-worker.coffee']
    worker.stdout.on 'data', (data) -> console.log data.toString().trim()

    app = spawn 'coffee', ['-wcj', 'yonro.js', 'bit-board.coffee', 'common.coffee', 'yonro.coffee']
    app.stdout.on 'data', (data) -> console.log data.toString().trim()

    app2 = spawn 'coffee', ['-wcj', 'solver.js', 'go-common.coffee', 'common.coffee', 'solver.coffee']
    app2.stdout.on 'data', (data) -> console.log data.toString().trim()

    app3 = spawn 'coffee', ['-wcj', 'chinro.js', 'go-common.coffee', 'go-shicho.coffee', 'common.coffee', 'chinro.coffee']
    app3.stdout.on 'data', (data) -> console.log data.toString().trim()

task 'test', 'unit test', ->
    console.log 'compiling'
    exec "coffee -cbj tests/testBitBoard.js #{bitBoardTest.join(' ')}", (err, stdout, stderr) ->
        if err?
            console.log stdout + stderr
        else
            exec "coffee -cbj tests/test-go-evaluate.js #{goEvaluateTest.join(' ')}", (err, stdout, stderr) ->
                if err?
                    console.log stdout + stderr
                else
                    console.log 'testing'
                    exec 'mocha tests', (err, stdout, stderr) ->
                        console.log if err? then stdout + stderr else stdout
