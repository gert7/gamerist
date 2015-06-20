# Store current port-room pairs in a database file

Nedb  = require('nedb')
debug = require('debug')('portlist')
Futures = require('futures')

require("coffee-script")
destroy_port = require('./destroy_port')

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

servers = new Nedb({filename: "server.db" + (if Config.testmode then ".test"), autoload: true})
servers.ensureIndex({fieldName: "port", unique: true})

unixtime = ->
  return Math.floor(Date.now() / 1000)

free_port = (port, callback) ->
  servers.remove({port: port}, ->
    debug("Freed port " + port + " in datastore")
    (callback || ->)()
  )

remove_timeout_ports = (callback) ->
  seq = Futures.sequence()
  get_all_ports((ports) ->
    i   = 0
    lim = ports.length
    (callback || ->)() if lim == 0
    for record in ports
      if(unixtime() > record.timeout)
        debug("Port " + record.port + " has timed out!")
        seq
        .then (next) ->
          destroy_port.destroy_port(record.port, next)
        .then (next, code) ->
          free_port(record.port, next)
      seq.then (next) ->
        i = i + 1
        (callback || ->)() if i >= lim
  )

remember_port = (port, room, callback) ->
  seq = Futures.sequence()
  .then (next) ->
    remove_timeout_ports(next)    
  .then (next) ->
    servers.insert({port: port, room: room, timeout: (unixtime() + Config.timeouts.timeout)}, next)
  .then (next, err, num) ->
    if err then debug("ERROR: Port " + port + " is still alive and in use!") else debug("Inserting room " + room + " into port " + port)
    (callback || ->)(err)
    
get_port = (port, callback) ->
  debug("Getting port " + port)
  servers.find({port: port}, (err, docs) ->
    if(docs[0]) then (callback || ->)(docs[0]) else (callback || ->)(undefined)
  )

get_all_ports = (callback) ->
  servers.find({port: { $in: Config.ports } }, (err, docs) ->
    (callback || ->)(docs)
  )

heartbeat_port = (port, callback) ->
  seq = Futures.sequence()
  temp = 
  seq
  .then (next) ->
    servers.find({port: port}, next)
  .then (next, err, docs) ->
    temp = docs[0]
    next(err, docs)
  return undefined unless temp
  seq
  .then (next, err, docs) ->
    servers.remove({port: port}, {multi: true}, next)
  .then (next) ->
    servers.insert({port: temp.port, room: temp.room, timeout: (unixtime() + Config.timeouts.timeout)}, next)
  .then (next, err) ->
    debug("Heartbeat for server on port " + port)
    (callback || -> )(err)

remove_all_ports = (callback) ->
  seq = Futures.sequence()
  get_all_ports((ports) ->
    i   = 0
    lim = ports.length
    (callback || ->)() if lim == 0
    for record in ports
      debug("Removing port " + record.port)
      seq
      .then (next) ->
        destroy_port.destroy_port(record.port, next)
      .then (next, code) ->
        #debug(code)
        free_port(record.port, next)
      seq.then (next) ->
        i = i + 1
        (callback || ->)() if i >= lim
  )

nactor = require("nactor")

plistactor = nactor.actor ->
  return {
    remember_port: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        remember_port(data.port, data.room, next)
      .then (next, err) ->
        async.reply(err)
    
    get_port: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        get_port(data.port, next)
      .then (next, record) ->
        async.reply(record)
        
    free_port: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        free_port(data.port, next)
      .then ->
        async.reply()
        
    heartbeat_port: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        heartbeat_port(data.port, next)
      .then (next, err) ->
        async.reply(err)
        
    remove_all_ports: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        remove_all_ports(next)
      .then ->
        async.reply()
  }

plistactor.init()

exports.remember_port  = (port, room, callback) ->
  plistactor.remember_port({port: port, room: room}, callback)

exports.get_port       = (port, callback) ->
  plistactor.get_port({port: port}, callback)
  
exports.free_port      = (port, callback) ->
  plistactor.free_port({port: port}, callback)
  
exports.heartbeat_port = (port, callback) ->
  plistactor.heartbeat_port({port: port}, callback)
  
exports.remove_all_ports= (callback) ->
  plistactor.remove_all_ports(null, callback)

