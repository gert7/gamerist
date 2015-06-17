amqp  = require("amqplib")
debug = require('debug')('northstream')

require("coffee-script")
fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

conn = amqp.connect(Config.rabbitmq.url)

q  = "gamerist.dispatch.down." + Config.selfname
ex = "gamerist.topic" + Config.rabbitmq.exsuffix

conn.then((conn) ->
  chan = conn.createChannel()
  chan = chan.then((ch) ->
    ch.assertQueue(q, {durable: true, manual_ack: true})
    ch.sendToQueue(q, new Buffer('something to do'))
  )
  return chan
).then(null, console.warn)

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
        debug(msg.content.toString())
        ch.ack(msg)
        ch.close()
        conn.close()
    )
  )
  return chan;
).then(null, console.warn)

debug("Begin parsing...")
a = JSON.parse('{"a" : "black people", "tit": ["spetznaz", 81, 9.2, false]}')
debug("Done parsing: " + a)

