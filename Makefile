test: test/test-bit-board.coffee test/test-go-common.coffee test/test-go-evaluate-common.coffee test/test-go-evaluate-bit-board.coffee go-common.coffee bit-board.coffee /tmp/go-evaluate-common.coffee /tmp/go-evaluate-bit-board.coffee
	mocha --compilers coffee:coffee-script/register --timeout 60000

/tmp/go-evaluate-common.coffee: go-common.coffee go-evaluate.coffee
	cat $^ > $@

/tmp/go-evaluate-bit-board.coffee: bit-board.coffee go-evaluate.coffee
	cat $^ > $@

test/test-go-evaluate-common.coffee: test/test-go-evaluate-common.coffee.header test/test-go-evaluate.coffee.body
	cat $^ > $@

test/test-go-evaluate-bit-board.coffee: test/test-go-evaluate-bit-board.coffee.header test/test-go-evaluate.coffee.body
	cat $^ > $@
