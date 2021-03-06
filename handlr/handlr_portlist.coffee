# Store current port-room pairs in a database file

Nedb  = require('nedb')
debug = require('debug')('portlist')
Futures = require('futures')

require("coffee-script")
destroy_port = require('./destroy_port')

Config = require("./handlr_config").conf

servers = new Nedb({filename: "server.db" + Config.selfname + (if Config.testmode then ".test"), autoload: true})
servers.ensureIndex({fieldName: "port", unique: true})

os = require('os')
if(not Config.testmode)
  system_total_memory = os.totalmem() - 256000000
else
  system_total_memory = 3100000000
  
debug(system_total_memory)

SINGLE_SERVER_BASE_RAM = 256000000
SINGLE_PLAYER_RAM = 16000000

unixtime = ->
  return Math.floor(Date.now() / 1000)

free_port = (port, callback) ->
  Futures.sequence()
  .then (next) ->
    servers.update({port: port}, {$set: {extant: false}}, {multi: true}, next)
  .then (next) ->
    servers.remove {port: port}, ->
      debug("Freed port " + port + " in datastore")
      (callback || ->)()

afor = require("async-for")

remove_timeout_port = (record, all, callback) ->
  inseq = Futures.sequence()
  if(all or (unixtime() > record.timeout))
    debug("Port " + record.port + " has timed out!")
    inseq
    .then (next) ->
      destroy_port.destroy_port(record.port, next)
    .then (next, code) ->
      free_port(record.port, next)
  inseq.then (next) ->
    (callback || ->)()

remove_timeout_ports = (all, callback) ->
  get_all_ports (ports) ->
    for portx in Config.ports
      inport = false
      for porty in ports
        if(porty.port == portx)
          inport = true
      if(inport == false)
        destroy_port.destroy_port(portx)
    iless  = (i) -> (i < ports.length)
    iadd   = (i) -> (i + 1)
    iloop  = (i, _break, _continue) ->
      remove_timeout_port(ports[i], all, _continue)
    mloop   = afor(0, iless, iadd, iloop)
    mloop(callback)

remember_port = (port, roomid, room, callback) ->
  seq = Futures.sequence()
  .then (next) ->
    remove_timeout_ports(false, next)    
  .then (next) ->
    servers.insert({port: port, roomid: roomid, room: room, timeout: (unixtime() + Config.timeouts.timeout)}, next)
  .then (next, err, num) ->
    if err then debug("ERROR: Port " + port + " is still alive and in use!") else debug("Inserting room " + roomid + " into port " + port)
    (callback || ->)(err)

calculate_put_ram = (records) ->
  put_ram_usage = 0
  for doc in records
    debug(records.length)
    pc = doc.room.playercount
    put_ram_usage += SINGLE_SERVER_BASE_RAM + (SINGLE_PLAYER_RAM * pc)
  return put_ram_usage

calculate_put_ram_ex = (cb) ->
  seq = Futures.sequence()
  .then (next) ->
    servers.find({}, next)
  .then (next, records) ->
    (cb || ->)(calculate_put_ram(records))

enough_room = (records, playercount) ->
  put_ram_usage = calculate_put_ram(records)
  put_ram_usage += SINGLE_SERVER_BASE_RAM + (SINGLE_PLAYER_RAM * playercount)
  debug(put_ram_usage)
  debug(system_total_memory)
  if(put_ram_usage < system_total_memory)
    return true
  else
    return false
  
remember_a_port = (roomid, room, callback) ->
  seq = Futures.sequence()
  .then (next) ->
    remove_timeout_ports(false, next)
  .then (next) ->
    servers.find({}, next)
  .then (next, err, records) ->
    if(enough_room(records, room.playercount))
      next(err, records)
    else
      callback(null, true)
  .then (next, err, records) ->
    debug(records)
    portns = []
    for portn in Config.ports
      portns.push({number: portn, taken: false})
    if records
      for doc in records
        for index, portdata of portns
          if(portdata.number == doc.port)
            portns[index].taken = true
    pn = null
    for portn in portns
      if(portn.taken == false)
        debug("Found free port " + portn.number)
        pn = portn.number
        break
    if pn
      remember_port(pn, roomid, room, ((err) -> next(pn, err)))
    else
      callback(null, true)
  .then (next, pn, err) ->
    callback(pn, err)

get_port = (port, callback) ->
  debug("Getting port " + port)
  servers.find({port: port}, (err, docs) ->
    if(docs[0]) then (callback || ->)(docs[0]) else (callback || ->)(undefined)
  )
  
get_port_by_id = (roomid, callback) ->
  servers.find({roomid: roomid}, (err, docs) ->
    if(docs[0]) then (callback || ->)(docs[0]) else (callback || ->)(undefined)
  )

# Retrieves all ports active according to the database
get_all_ports = (callback) ->
  servers.find({port: { $in: Config.ports }}, (err, docs) ->
    (callback || ->)(docs)
  )

heartbeat_port = (port, callback, newTimeout) ->
  seq = Futures.sequence()
  temp = 
  seq
  .then (next) ->
    remove_timeout_ports(false, next)
  .then (next) ->
    servers.find({port: port}, next)
  .then (next, err, docs) ->
    temp = docs[0]
    if temp
      next(err, docs)
    else
      debug("can't find temp on port " + port)
      (callback || -> )(true)
  .then (next, err, docs) ->
    servers.update({port: port}, { $set: {timeout: (newTimeout or (unixtime() + Config.timeouts.timeout))}}, {}, next)
  .then (next, err) ->
    debug("Heartbeat for server on port " + port)
    (callback || -> )(err)

remove_all_ports = (callback) ->
  remove_timeout_ports(true, callback)

nactor = require("nactor")

plistactor = nactor.actor ->
  return {
    remember_port: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        remember_port(data.port, data.roomid, data.room, next)
      .then (next, err) ->
        async.reply(err)
    
    remember_a_port: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        remember_a_port(data.roomid, data.room, next)
      .then (next, port) ->
        async.reply(port)
    
    get_port: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        get_port(data.port, next)
      .then (next, record) ->
        async.reply(record)
    
    get_port_by_id: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        get_port_by_id(data.roomid, next)
      .then (next, record) ->
        async.reply(record)
        
    get_all_ports: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        get_all_ports(next)
      .then (next, records) ->
        async.reply(records)
    
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
        heartbeat_port(data.port, next, data.timeout)
      .then (next, err) ->
        async.reply(err)
        
    remove_all_ports: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        remove_all_ports(next)
      .then ->
        async.reply()
    
    remove_timeout_port: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        remove_timeout_port(data.record, data.all, next)
      .then ->
        async.reply()
    
    remove_timeout_ports: (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        remove_timeout_ports(false, next)
      .then ->
        async.reply()
  }

plistactor.init()

exports.remember_port  = (port, roomid, room, callback) ->
  plistactor.remember_port({port: port, roomid: roomid, room: room}, callback)

exports.remember_a_port  = (roomid, room, callback) ->
  plistactor.remember_a_port({roomid: roomid, room: room}, callback)

exports.get_port       = (port, callback) ->
  plistactor.get_port({port: port}, callback)

exports.get_port_by_id = (roomid, callback) ->
  plistactor.get_port_by_id({roomid: roomid}, callback)
  
exports.get_all_ports = (callback) ->
  plistactor.get_all_ports(null, callback)

exports.free_port      = (port, callback) ->
  plistactor.free_port({port: port}, callback)
  
exports.heartbeat_port = (port, callback, timeout) ->
  plistactor.heartbeat_port({port: port, timeout: timeout}, callback)
  
exports.remove_all_ports= (callback) ->
  plistactor.remove_all_ports(null, callback)

exports.remove_timeout_port = (record, all, callback) ->
  plistactor.remove_timeout_port({record: record, all: all}, callback)

exports.remove_timeout_ports = (callback) ->
  plistactor.remove_timeout_ports(null, callback)
  
exports.calculate_put_ram = (callback) ->
  calculate_put_ram_ex(callback)

setInterval((() -> plistactor.remove_timeout_ports(null, ->)), 7000)

