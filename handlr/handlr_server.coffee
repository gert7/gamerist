Nedb  = require('nedb')
debug = require('debug')('servers')
Futures = require('futures')

servers = new Nedb({filename: "server.db", autoload: true})

remember_port = (port, room) ->
  servers.update({port: port}, {port: port, room: room}, {upsert: true})
    
get_port = (port, callback) ->
  servers.find({port: port}, (err, docs) ->
    if(docs[0]) then callback(docs[0]) else callback(undefined)
  )
  
free_port = (port) ->
  servers.remove({port: port})


