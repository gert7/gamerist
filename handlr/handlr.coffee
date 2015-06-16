amqp = require('amqplib')
nedb = require('nedb')
path = require('path')
debug = require('debug')('front')

require("coffee-script")

require('./handlr_portlist')

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

conn = amqp.connect(Config.rabbitmq.url)

q  = "gamerist.dispatch.down." + Config.selfname
ex = "gamerist.topic" + Config.rabbitmq.exsuffix

conn.then((conn) ->
  chan = conn.createChannel()
  chan = chan.then((ch) ->
    ch.assertQueue(q, {durable: true})
    ch.sendToQueue(q, new Buffer('something to do'))
  )
  return chan
).then(null, console.warn)

