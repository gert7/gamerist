# Store current port-room pairs in a database file

Nedb  = require('nedb')
debug = require('debug')('portlist')
Futures = require('futures')

require("coffee-script")
destroy_port = require('./destroy_port')

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

servers = new Nedb({filename: "server.db", autoload: true})

unixtime = ->
  return Math.floor(Date.now() / 1000)

free_port = (port, callback) ->
  servers.remove({port: port}, {multi: true}, ->
    debug("Freed port " + port + " in datastore")
    (callback || ->)()
  )

remove_timeout_ports = (callback) ->
  get_all_ports((ports) ->
    for record in ports
      debug(record)
      if(unixtime() > record.timeout)
        destroy_port.destroy_port(record.port)
        free_port(record.port, callback)
  )

remember_port = (port, room, callback) ->
  servers.update({port: port}, {port: port, room: room, timeout: (Math.floor(Date.now() / 1000) + Config.timeouts.timeout)}, {upsert: true}, ->
    (callback || ->)()
  )
    
get_port = (port, callback) ->
  servers.find({port: port}, (err, docs) ->
    if(docs[0]) then (callback || ->)(docs[0]) else (callback || ->)(undefined)
  )

get_all_ports = (callback) ->
  servers.find({port: { $in: Config.ports } }, (err, docs) ->
    (callback || ->)(docs)
  )
  
heartbeat_port = (port, callback) ->
  remove_timeout_ports()
  get_port(27015, (rec) ->
    debug(rec)
  )
  debug(unixtime())

exports.remember_port  = remember_port
exports.get_port       = get_port
exports.free_port      = free_port
exports.heartbeat_port = heartbeat_port

#remember_port(27015, 11)
heartbeat_port()

