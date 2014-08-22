assert = require 'assert'

describe 'functions ', ->
    describe 'countBits', ->
        it 'should return 0', ->
            assert.equal countBits(0), 0
        it 'should return 1', ->
            assert.equal countBits(2), 1
        it 'should return 2', ->
            assert.equal countBits(6), 2
    describe 'positionToBit', ->
        it 'should return 2', ->
            assert.equal positionToBit([1,1]), 0x02
    describe 'adjacent', ->
        it 'should return 2', ->
            p = positionToBit [1, 1]
            assert.equal adjacent(p, p), positionsToBits [[2, 1], [1, 2]]
    describe 'string', ->
        it 'should return one stone', ->
            p = positionToBit [1, 1]
            assert.equal string(p, p), p
    describe 'captured', ->
        it 'should return one stone', ->
            p = positionToBit [1, 1]
            assert.equal captured(p, adjacent(p, p)), p
