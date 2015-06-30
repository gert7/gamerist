amqp  = require("amqplib")
debug = require('debug')('northstream')

require("coffee-script")
serverspawn = require("./handlr_serverspawn")
fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

conn = amqp.connect(Config.rabbitmq.url)

q  = "gamerist.dispatch.down." + Config.selfname
ex = "gamerist.topic" + Config.rabbitmq.exsuffix

SAMPLE = '{"protocol_version":1,"type":"spinup","roomdata":{"game":"team fortress 2","map":"ctf_2fort","playercount":16,"wager":5,"server":"centurion","players":[{"id":1,"ready":0,"wager":5,"avatar":"http://","steamname":"Hello","steamid":"vanwe98wn38328ng2","timeout":1435667836}]}}'

conn.then((conn) ->
  chan = conn.createChannel()
  chan = chan.then((ch) ->
    ch.assertQueue(q, {durable: true, manual_ack: true})
    ch.sendToQueue(q, new Buffer(SAMPLE))
    ch.sendToQueue(q, new Buffer(SAMPLE))
    ch.sendToQueue(q, new Buffer(SAMPLE))
    ch.sendToQueue(q, new Buffer(SAMPLE))
    ch.sendToQueue(q, new Buffer(SAMPLE))
  )
  return chan
).then(null, console.warn)

handle_mq_message = (data, callback) ->
  debug("Received MQ data!")
  debug(data)
  if(data.protocol_version == 1)
    if(data.type == "spinup")
      serverspawn()
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
    # ch.prefetch(1) # one message at a time !!!
    ch.consume(q, (msg) ->
      #debug("a new message!")
      if (msg != null)
        msgc = JSON.parse(msg.content.toString())
        #debug(msgc)
        northstream.handle_mq_message(msgc, ->)
        ch.ack(msg)
    )
  )
  return chan;
).then(null, console.warn)

