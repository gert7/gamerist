require("coffee-script")
Futures  = require("futures")
portlist = require("../handlr_portlist")
expect   = require("chai").expect
debug    = require("debug")("test")
fs   = require('fs')
path = require("path")

describe "portlist", ->
  describe "remember_port", ->
    beforeEach (done) ->
      portlist.remove_all_ports(done)
    it "remembers the port", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 71, next)
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        debug(record)
        expect(record.port).to.equal 27015
        expect(record.room).to.equal 71
        done()
    it "callbacks an error if the port is already taken", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 72, next)
      .then (next) ->
        portlist.remember_port(27015, 78, next)
      .then (next, err) ->
        expect(err).not.to.equal null
        done()
    it "doesn't raise an error if available", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 81, next)
      .then (next, err) ->
        debug err
        expect(err).to.equal null
        done()
        
