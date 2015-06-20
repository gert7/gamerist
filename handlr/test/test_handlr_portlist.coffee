require("coffee-script")
Futures  = require("futures")
portlist = require("../handlr_portlist")
expect   = require("chai").expect
debug    = require("debug")("test")
fs   = require('fs')
path = require("path")

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
    it "doesn't cause a race condition", (done) ->
      portlist.remember_port(27015, 101, ->)
      portlist.remember_port(27015, 102, ->)
      seq = Futures.sequence()      
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        debug record
        expect(record.room).to.equal 101
        done()
  describe "get_port", ->
    it "returns the correct record for the port", (done) ->
      seq = Futures.sequence()
      .then (next) ->
        portlist.remember_port(27015, 94, next)
      .then (next) ->
        portlist.get_port(27015, next)
      .then (next, record) ->
        expect(record.port).to.equal 27015
        expect(record.room).to.equal 94
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
        portlist.remember_port(27015, 95, next)
      .then (next, record) ->
        portlist.free_port(27015, next)
      .then (next) ->
        portlist.remember_port(27015, 96, next)
      .then (next, err) ->
        expect(err).to.equal null
        done()
        
