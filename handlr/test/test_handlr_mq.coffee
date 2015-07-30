require("coffee-script")
Futures  = require("futures")
portlist = require("../handlr_portlist")
northstream = require("../handlr_mq_sub")
expect   = require("chai").expect
debug    = require("debug")("test")
fs   = require('fs')
path = require("path")

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

betweenEach = (done) ->
  seq = Futures.sequence()
    .then (next) ->
      portlist.remove_all_ports(next)
    .then (next) ->
      debug("Succesfully removed all ports for testing")
      done()
      
DUMMY_DATA = {"protocol_version":1,"type":"spinup","id":81,"roomdata":{"game":"team fortress 2","map":"ctf_2fort","playercount":16,"wager":5,"server":"centurion","players":[{"id":1,"ready":0,"wager":5,"avatar":"http://","steamname":"Hello","team":3,"steamid":"STEAM_0:1:18525940","timeout":1435667836}]}}

describe "MQ", ->
  beforeEach(betweenEach)
  afterEach(betweenEach)
  describe "handle_mq_message", ->
    it "launches a new server correctly", (done) ->
      Futures.sequence()
      .then (next) ->
        northstream.handle_mq_message(DUMMY_DATA, next)
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        expect(record.roomid).to.equal 81
        expect(record.room.players[0].steamid).to.equal "STEAM_0:1:18525940"
        done()
    it "cancels a server correctly", (done) ->
      Futures.sequence()
      .then (next) ->
        northstream.handle_mq_message(DUMMY_DATA, next)
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        expect(record.roomid).to.equal 81
        next()
      .then (next) ->
        northstream.handle_mq_message({"protocol_version": 1, "type": "cancel", "id": 81}, next)
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        expect(record).to.equal undefined
        done()
        
