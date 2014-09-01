{ BLACK, WHITE, EMPTY, MAX_SCORE, boardsToString, opponentOf } = require '../go-common.coffee'
{ OnBoard } = require '../array-board.coffee'
{ evaluate } = require '../go-evaluate.coffee'
{ testEvaluate } = require './lib/test-go-evaluate.coffee'

describe 'array-board', testEvaluate 'array-board'
