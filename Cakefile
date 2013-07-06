{spawn, exec} = require 'child_process'

task 'app', 'build app', ->
    worker = spawn 'coffee', ['-wcj', 'go-worker.js', 'go-common.coffee', 'go-evaluate.coffee', 'go-worker.coffee']
    worker.stdout.on 'data', (data) -> console.log data.toString().trim()

    app = spawn 'coffee', ['-wcj', 'yonro.js', 'go-common.coffee', 'go-evaluate.coffee', 'yonro.coffee']
    app.stdout.on 'data', (data) -> console.log data.toString().trim()

task 'test', 'build test', ->
    test = spawn 'coffee', ['-wcbj', 'test/go-evaluate.js', 'go-common.coffee', 'go-evaluate.coffee']
    test.stdout.on 'data', (data) -> console.log data.toString().trim()

    spec = spawn 'coffee', ['-wc','spec']
    spec.stdout.on 'data', (data) -> console.log data.toString().trim()
