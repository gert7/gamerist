debug = require('debug')('maintain')
Nedb  = require('nedb')
Futures = require('futures')

Config = require("./handlr_config").conf

maintenance = new Nedb({filename: "maintenance.db" + Config.selfname + (if Config.testmode then ".test"), autoload: true})

MAINTENANCE_STARTED  = 1
NEW_GAMES_DISABLED   = 2
UPDATING_STARTED     = 4
UPDATING_FINISHED    = 8
NEW_GAMES_ENABLED    = 16
MAINTENANCE_FINISHED = 32

NAME_TF2 = "team fortress 2"
NAME_CSS = "counter strike source"

resumeTF2 = ->
  Futures.sequence()
  .then (next) ->
    maintenance.find({game: NAME_TF2}, next)
  .then (next, record) ->
    if record
      debug("Resuming updates for TF2...")

resumeCSS = ->
  Futures.sequence()
  .then (next) ->
    maintenance.find({game: NAME_CSS}, next)
  .then (next, record) ->
    if record
      debug("Resuming updates for CSS...")
      
resume = () ->
  resumeTF2()
  resumeCSS()
  
start_updating_game = (game, cb) ->
  Futures.sequence()
  .then(next) ->
    maintenance.insert({game: game, state: MAINTENANCE_STARTED}, next)
  .then(next) ->
    

nactor = require("nactor")

hmactor = nactor.actor ->
  return {
    updateGame: (data, async) ->
      async.enable()
      Futures.sequence()
      .then(next) ->
        start_updating_game(data.game, next)
      .then(next) ->
        async.reply()
  }

resume()
debug("Maintaining...")

