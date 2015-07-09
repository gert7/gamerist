amqp  = require("amqplib")
debug = require('debug')('northstream')

require("coffee-script")
serverspawn = require("./handlr_serverspawn")
fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

conn = amqp.connect(Config.rabbitmq.url)

q  = "gamerist.dispatch.down." + Config.selfname
qu = "gamerist.dispatch.upstream"
ex = "gamerist.topic" + Config.rabbitmq.exsuffix

SAMPLE = '{"protocol_version":1,"type":"spinup","id":81,"roomdata":{"game":"team fortress 2","map":"ctf_2fort","playercount":16,"wager":5,"server":"centurion","players":[{"id":1,"ready":0,"wager":5,"avatar":"http://","steamname":"Hello","team":3,"steamid":"STEAM_0:1:18525940","timeout":1435667836}]}}'

conn.then((conn) ->
  chan = conn.createChannel()
  chan = chan.then((ch) ->
    ch.assertQueue(q, {durable: true, manual_ack: true})
    ch.sendToQueue(q, new Buffer(SAMPLE))
  )
  return chan
).then(null, console.warn)

handle_mq_message = (data, callback) ->
  debug("Received MQ data!")
  debug(data)
  if(data.protocol_version == 1)
    if(data.type == "spinup")
      Futures.sequence()
      .then (next) ->
        serverspawn.spin_up(data.id, data.roomdata, next)
      .then (next, err, port) ->
        conn.then((conn) ->
          chan = conn.createChannel()
          chan = chan.then((ch) ->
            ch.assertQueue(qu, {durable: true, manual_ack: true})
            debug("Sending preliminary server creation confirmation northstream")
            ch.sendToQueue(qu, new Buffer('{"protocol_version":1, "type": "creating", "id": ' + data.id + ', "port": ' + port + '}'))
          )
          return chan
        ).then(null, console.warn)
        callback()
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
  chan = chan.then((ch) ->
    ch.assertQueue(q)
    ch.assertExchange(ex, "topic", {durable: false, })
    ch.bindQueue(q, ex, q)
    ch.prefetch(1) # one message at a time !!!
    ch.consume(q, (msg) ->
      debug("a new message!")
      if (msg != null)
        msgc = JSON.parse(msg.content.toString())
        northstream.handle_mq_message(msgc, (->))
        ch.ack(msg)
    )
  )
  return chan;
).then(null, console.warn)

exports.send_upstream = (msg) ->
  conn.then((conn) ->
    chan = conn.createChannel()
    chan = chan.then((ch) ->
      ch.assertQueue(qu, {durable: true, manual_ack: true})
      ch.sendToQueue(qu, new Buffer(msg))
    )
    return chan
  ).then(null, console.warn)

