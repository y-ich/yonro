YONRO = go-worker.js yonro.js
SOLVER = go-worker.js yonro.js
CHINRO = chinro.js

all: $(YONRO) $(SOLVER) $(CHINRO)

yonro: $(YONRO)
solver: $(SOLVER)
chinro: $(CHINRO)

go-worker.js: go-common.coffee bit-board.coffee go-evaluate.coffee go-worker.coffee
	cat $^ | coffee --compile --stdio > $@

yonro.js: go-common.coffee bit-board.coffee go-evaluate.coffee common.coffee yonro.coffee
	cat $^ | coffee --compile --stdio > $@

solver.js: go-common.coffee common.coffee solver.coffee
	cat $^ | coffee --compile --stdio > $@

chinro.js: go-common.coffee go-shicho.coffee common.coffee chinro.coffee
	cat $^ | coffee --compile --stdio > $@

clean:
	rm $(sort $(YONRO) $(SOLVER) $(CHINRO))

test: test/test-array-board.coffee test/test-bit-board.coffee test/test-go-evaluate-bit-board.coffee go-common.coffee array-board.coffee bit-board.coffee go-evaluate.coffee
	mocha -b --compilers coffee:coffee-script/register --timeout 10000
