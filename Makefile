test: test/test-go-common.coffee test/test-bit-board.coffee test/test-go-evaluate.coffee go-common.coffee bit-board.coffee go-evaluate.coffee
	mocha -b  --compilers coffee:coffee-script/register
