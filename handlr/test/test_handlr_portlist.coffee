require("coffee-script")
Futures  = require("futures")
portlist = require("../handlr_portlist")
expect   = require("chai").expect
debug    = require("debug")("test")
fs   = require('fs')
path = require("path")

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

describe "portlist", ->
  beforeEach (done) ->
    seq = Futures.sequence()
    .then (next) ->
      portlist.remove_all_ports(next)
    .then (next) ->
      debug("Succesfully removed all ports for testing")
      done()
  describe "remember_port", ->
    it "remembers the port", (done) ->
      debug("Starting remember port")
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 71, {}, next)
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        debug(record)
        expect(record.port).to.equal 27015
        expect(record.roomid).to.equal 71
        done()
    it "callbacks an error if the port is already taken", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 72, {}, next)
      .then (next) ->
        portlist.remember_port(27015, 78, {}, next)
      .then (next, err) ->
        expect(err).not.to.equal null
        done()
    it "doesn't raise an error if available", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 81, {}, next)
      .then (next, err) ->
        debug err
        expect(err).to.equal null
        done()
    it "doesn't cause a race condition", (done) ->
      portlist.remember_port(27015, 101, {}, ->)
      portlist.remember_port(27015, 102, {}, ->)
      seq = Futures.sequence()      
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        debug record
        expect(record.roomid).to.equal 101
        done()
  describe "get_port", ->
    it "returns the correct record for the port", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 94, {}, next)
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        expect(record.port).to.equal 27015
        expect(record.roomid).to.equal 94
        done()
    it "returns undefined otherwise", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        expect(record).to.equal undefined
        done()
  describe "free_port", ->
    it "frees the port for use", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 95, {}, next)
      .then (next, record) ->
        portlist.free_port(27015, next)
      .then (next) ->
        portlist.remember_port(27015, 96, {}, next)
      .then (next, err) ->
        expect(err).to.equal null
        done()
  describe "remember_a_port", ->
    it "remembers some available port", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_a_port(192, {playercount: 16}, next)
      .then (next, port, err) ->
        expect(port).to.equal Config.ports[0]
        portlist.get_port(Config.ports[0], next)
      .then (next, record) ->
        expect(record.roomid).to.equal 192
        done()
    it "remembers the next available port", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_a_port(193, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).to.equal Config.ports[0]
        portlist.remember_a_port(194, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).to.equal Config.ports[1]
        portlist.remember_a_port(196, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).to.equal Config.ports[2]
        portlist.remember_a_port(197, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).to.equal Config.ports[3]
        done()
    it "fails due to lack of memory", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_a_port(193, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).to.equal Config.ports[0]
        portlist.remember_a_port(194, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).to.equal Config.ports[1]
        portlist.remember_a_port(196, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).to.equal Config.ports[2]
        portlist.remember_a_port(197, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).to.equal Config.ports[3]
        portlist.remember_a_port(197, {playercount: 32}, next)
      .then (next, port) ->
        expect(port).not.to.equal Config.ports[4]
        done()
  describe "heartbeat_port", ->
    it "heartbeats a port", (done) ->
      iport =
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_a_port(198, {playercount: 32}, next)
      .then (next, port) ->
        iport = port
        portlist.get_port(port, next)
      .then (next, record) ->
        expect(record.timeout).not.to.equal undefined
        next(record.port)
      .then (next, port) ->
        portlist.heartbeat_port(port, next, 400)
      .then (next, err) ->
        portlist.get_port(iport, next)
      .then (next, record) ->
        expect(record.room.playercount).to.equal 32
        expect(record.timeout).to.equal 400
        done()
        
