{ BLACK, WHITE, EMPTY, MAX_SCORE, boardsToString, opponentOf } = require '../go-common.coffee'
{ OnBoard } = require '../bit-board.coffee'
{ evaluate } = require '../go-evaluate.coffee'
{ testEvaluate } = require './lib/test-go-evaluate.coffee'

describe 'bit-board', testEvaluate 'bit-board'
