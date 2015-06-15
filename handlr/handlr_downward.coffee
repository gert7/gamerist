# Manages handlr <-> gameserver communications after spinup
# After spinup, the gameserver itself will contact handlr
# over TCP on port 1996 as a client

net   = require('net')
debug = require('debug')('downstream')

# Format:
#
# <- AX = I AM ALIVE
# -> CA = COPY 
# <- RS = RESULTS

crunch_data = (data) ->
  cursor = 0
  loop
    break if (cursor >= data.length)
    if()

server = net.createServer((c) ->
  debug('client connected')
  c.setEncoding("utf8")
  c.on('end', () ->
    debug('Client disconnected')
  )
  c.on('data', (data) ->
    crunch_down(data)
  )
)

server.listen(8124, () ->
  debug('server bound')
)

client = net.connect({port: 8124}, () ->
  debug('connected to server!')
  client.write('abcde')
  setTimeout(() ->
    client.write("fghij")
  , 1000)
)
client.on('data', (data) ->
  console.log(data.toString())
  client.end()
)
client.on('end', () ->
  console.log('disconnected from server')
)

