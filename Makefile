test: test/*.coffee go-common.coffee bit-board.coffee /tmp/go-evaluate-common.coffee /tmp/go-evaluate-bit-board.coffee
	mocha -b  --compilers coffee:coffee-script/register

/tmp/go-evaluate-common.coffee: go-common.coffee go-evaluate.coffee
	cat $^ > $@

/tmp/go-evaluate-bit-board.coffee: bit-board.coffee go-evaluate.coffee
	cat $^ > $@
