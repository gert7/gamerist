amqp  = require("amqplib")
debug = require('debug')('northstream')

require("coffee-script")
serverspawn = require("./handlr_serverspawn")
portlist    = require("./handlr_portlist")

Config = require("./handlr_config").conf

conn = amqp.connect(Config.rabbitmq.url)

q  = "gamerist.dispatch.down." + Config.selfname
qu = "gamerist.dispatch.upstream"
ex = "gamerist.topic" + Config.rabbitmq.exsuffix

SAMPLE = '{"protocol_version":1,"type":"spinup","id":81,"roomdata":{"game":"team fortress 2","map":"ctf_2fort","playercount":16,"wager":5,"server":"centurion","players":[{"id":1,"ready":0,"wager":5,"avatar":"http://","steamname":"Hello","team":3,"steamid":"STEAM_0:1:18525940","timeout":1435667836}]}}'

unixtime = ->
  return Math.floor(Date.now() / 1000)

sendup = (data, callback) ->
  conn.then((conn) ->
    chan = conn.createChannel()
    chan = chan.then((ch) ->
      ch.assertQueue(qu, {durable: true, manual_ack: true})
      ch.sendToQueue(qu, new Buffer(data))
    )
    return chan
  ).then(null, console.warn)
  (callback || ->)()

handle_mq_message = (data, callback) ->
  debug("Received MQ data!")
  debug(data)
  debug("Data timed out!") if (data.timeout and data.timeout < unixtime())
  if(data.protocol_version == 1 and (!data.timeout or data.timeout > unixtime()))
    if(data.type == "spinup")
      Futures.sequence()
      .then (next) ->
        serverspawn.spin_up(data.id, data.roomdata, next)
      .then (next, err, port) ->
        sendup('{"protocol_version":1, "server": "' + Config.selfname + '", "type": "creating", "id": ' + data.id + ', "port": ' + port + '}', callback)
    else if (data.type == "cancel")
      Futures.sequence()
      .then (next) ->
        portlist.get_port_by_id(data.id, next)
      .then (next, record) ->
        if record
          portlist.remove_timeout_port(record, true, next)
        else
          next()
      .then (next) ->
        sendup('{"protocol_version":1, "server": "' + Config.selfname + '", "type": "pcanceled", "id": ' + data.id + '}', callback)
    else if (data.type == "heartbeat")
      sendup('{"protocol_version":1, "server": "' + Config.selfname + '", "type": "heartbeat", "signature": "' + data.signature + '}', callback)
    else
      callback()
  else
    callback()

nactor  = require("nactor")
Futures = require("futures")

northstream = nactor.actor ->
  return {
    handle_mq_message : (data, async) ->
      async.enable()
      Futures.sequence()
      .then (next) ->
        handle_mq_message(data, next)
      .then ->
        async.reply()
  }
  
northstream.init()

conn.then((conn) ->
  chan = conn.createChannel()
  chan = chan.then (ch) ->
    ch.assertQueue(q)
    ch.assertExchange(ex, "topic", {durable: false, })
    ch.bindQueue(q, ex, q)
    ch.prefetch(1) # one message at a time !!!
    ch.consume q, (msg) ->
      debug("a new message!")
      if (msg != null)
        msgc = JSON.parse(msg.content.toString())
        northstream.handle_mq_message(msgc, (->))
        ch.ack(msg)
  return chan;
).then(null, console.warn)

exports.handle_mq_message = (data, callback) ->
  northstream.handle_mq_message(data, callback)

exports.send_upstream = (msg, callback) ->
  sendup(msg, callback)

pro_tempore_report = () ->
  Futures.sequence()
  .then (next) ->
    portlist.get_all_ports(next)
  .then (next, records) ->
    sendup('{"protocol_version": 1, "type": "general_report", "timestamp":' + unixtime() + ', "contents":' + JSON.stringify(records) + '}')

setInterval(pro_tempore_report, 7000)

