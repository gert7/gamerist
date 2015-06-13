amqp = require('amqplib')
nedb = require('nedb')

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

conn = amqp.connect("amqp://" + Config.rabbitmq.url)

q = "gamerist.dispatch.down." + Config.selfname

conn.then((conn) ->
  chan = conn.createChannel()
  chan = chan.then((ch) ->
    ch.assertQueue(q, {durable: true})
    ch.sendToQueue(q, new Buffer('something to do'))
  )
  return chan
).then(null, console.warn)

conn.then((conn) ->
  chan = conn.createChannel()
  chan = chan.then((ch) ->
    ch.assertQueue(q)
    ch.consume(q, (msg) ->
      if (msg != null)
        console.log(msg.content.toString())
        ch.ack(msg)
    )
  )
  return chan;
).then(null, console.warn)

sexec = require("child_process").spawn

child = sexec("nodejs", ["handlrc.js"])

console.log("PID: " + child.pid)

child.stdout.on('data', (data) ->
  console.log('stdout: ' + data)
  child.kill()
)

child.on('close', (code) ->
  console.log('child process exited with code ' + code)
)


