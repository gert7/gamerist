require("coffee-script")
Futures  = require("futures")
maintain = require("../handlr_maintain")
portlist = require("../handlr_portlist")
expect   = require("chai").expect
debug    = require("debug")("test")
fs   = require('fs')
path = require("path")

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

describe "maintain", ->
  beforeEach (done) ->
    Futures.sequence()
    .then (next) ->
      maintain.clear_all_checklists(next)
    .then (next) ->
      portlist.remove_all_ports(next)
    .then (next) ->
      done()
  it "remembers when maintaining a game", (done) ->
    Futures.sequence()
    .then (next) ->
      maintain.update_game("team fortress 2", next)
    .then (next, err) ->
      expect(err).to.eq 0
      maintain.update_game("team fortress 2", next)
    .then (next, err) ->
      expect(err).to.eq 1
      done()
  it "waits when games are unfinished", (done) ->
    Futures.sequence()
    .then (next) ->
      portlist.remember_a_port(251, {game: "team fortress 2", playercount: 16}, next)
    .then (next) ->
      maintain.update_game("team fortress 2", next)
    .then (next, err) ->
      expect(err).to.eq -1
      done()
  it "only affects the same game", (done) ->
    Futures.sequence()
    .then (next) ->
      maintain.update_game("team fortress 2", next)
    .then (next, err) ->
      expect(err).to.eq 0
      maintain.update_game("counter strike source", next)
    .then (next, err) ->
      expect(err).to.eq 0
      done()
  it "only waits for games of its own type", (done) ->
    Futures.sequence()
    .then (next) ->
      portlist.remember_a_port(251, {game: "counter strike source", playercount: 16}, next)
    .then (next) ->
      maintain.update_game("team fortress 2", next)
    .then (next, err) ->
      expect(err).to.eq 0
      done()
      
