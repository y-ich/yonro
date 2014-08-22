test: tests/test-go-common.js tests/testBitBoard.js tests/test-go-evaluate.js
	mocha tests

tests/test-go-common.js: tests/test-go-common.coffee go-common.coffee
	coffee -cbj $@ $^

tests/testBitBoard.js: tests/testBitBoard.coffee bit-board.coffee
	coffee -cbj $@ $^

tests/test-go-evaluate.js: tests/test-go-evaluate.coffee bit-board.coffee go-evaluate.coffee
	coffee -cbj $@ $^
