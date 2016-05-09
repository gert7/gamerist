debug = require('debug')('maintain')
Nedb  = require('nedb')
Futures = require('futures')

portlist = require("./handlr_portlist")

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
    maintenance.find({game: NAME_TF2, extant: true}, next)
  .then (next, err, docs) ->
    if(docs.length > 0)
      debug("Resuming updates for TF2...")

resumeCSS = ->
  Futures.sequence()
  .then (next) ->
    maintenance.find({game: NAME_CSS, extant: true}, next)
  .then (next, err, docs) ->
    if(docs.length > 0)
      debug("Resuming updates for CSS...")
      
resume = () ->
  resumeTF2()
  resumeCSS()
  
# 1  = already updating
# 0  = now updating
# -1 = waiting until rooms are empty
start_updating_game = (game, cb) ->
  Futures.sequence()
  .then (next) ->
    maintenance.find({game: game, extant: true}, next)
  .then (next, err, docs) ->
    if(docs.length == 0)
      next()
    else
      (cb || ->)(1)
  .then (next) ->
    maintenance.insert({game: game, extant: true, state: MAINTENANCE_STARTED}, next)
  .then (next) ->
    portlist.get_all_ports(next)
  .then (next, docs) ->
    game_in_progress = false
    for d in docs
      if(d.room.game == game and d.extant != false)
        debug("game is in progress")
        game_in_progress = true
    if game_in_progress
      (cb || ->)(-1)
    else
      maintenance.update({game: game}, {game: game, extant: true, state: MAINTENANCE_STARTED}, {})
      (cb || ->)(0)

nactor = require("nactor")

hmactor = nactor.actor ->
  return {
    update_game: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        start_updating_game(data.game, next)
      .then (next, err) ->
        async.reply(err)
  }

hmactor.init()

resume()

exports.update_game = (game, cb) ->
  hmactor.update_game({game: game}, cb)

exports.clear_all_checklists = (cb) ->
  maintenance.update({}, {$set: {extant: false}}, {multi: true}, cb)
  maintenance.remove({extant: false}, {multi: true}, (->))

debug("Maintaining...")

