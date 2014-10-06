###
require('nodetime').profile
    accountKey: '530bf9b055c316e4b08ffbd05c3f0d8d797d6b1d'
    appName: 'yonro'
###
{ boardsToString } = require "./go-common.coffee"
{ compare, evaluate } = require './go-evaluate.coffee'
{ OnBoard } = require "./bit-board.coffee"

board = OnBoard.fromString """
    O X 
    XX  
        
      X 
    """
evaluate [board], board.base.WHITE


