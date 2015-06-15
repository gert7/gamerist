amqp = require('amqplib')
nedb = require('nedb')
path = require('path')
debug = require('debug')('front')

require("coffee-script")
require('./handlr_server')

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

conn = amqp.connect(Config.rabbitmq.url)

q  = "gamerist.dispatch.down." + Config.selfname
ex = "gamerist.topic" + Config.rabbitmq.exsuffix

#conn.then((conn) ->
#  chan = conn.createChannel()
#  chan = chan.then((ch) ->
#    ch.assertQueue(q, {durable: true})
#    ch.sendToQueue(q, new Buffer('something to do'))
#  )
#  return chan
#).then(null, console.warn)

conn.then((conn) ->
  chan = conn.createChannel()
  chan = chan.then((ch) ->
    ch.assertQueue(q)
    ch.assertExchange(ex, "topic", {durable: false})
    ch.bindQueue(q, ex, q)
    ch.consume(q, (msg) ->
      if (msg != null)
        debug(msg.content.toString())
        ch.ack(msg)
    )
  )
  return chan;
).then(null, console.warn)

sexec = require("child_process").spawn

debug(path.resolve("../steamcmd"))
child = sexec("nodejs", ["handlrc.js"])

debug("PID: " + child.pid)

child.stdout.on('data', (data) ->
  debug('stdout: ' + data)
  child.kill()
)

child.on('close', (code) ->
  debug('child process exited with code ' + code)
)

