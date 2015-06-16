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

