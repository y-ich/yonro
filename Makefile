test: test/test-array-board.coffee test/test-bit-board.coffee test/test-go-evaluate-bit-board.coffee go-common.coffee array-board.coffee bit-board.coffee go-evaluate.coffee
	mocha -b --compilers coffee:coffee-script/register --timeout 600000
