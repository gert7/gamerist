# Manages handlr <-> gameserver communications after spinup
# After spinup, the gameserver itself will contact handlr
# over TCP on port 1996 as a client

net   = require('net')
debug = require('debug')('southstream')

# Message format (square brackets not included, numbers are plain ASCII):
# hndlr -> A[decimal string]\n = Acknowledged message number N
# hndlr <- A[decimal string]\n = Acknowledged message number N

# the following messages are preceded by [msgindex]| and followed by \n
# hndlr <- I = Connection established
# hndlr <- L[index] = Send the next player list item
# hndlr -> L[index|steamid1|team number] = add player to list(index, steamid, teamnumber, seperated by pipe, up to 32 characters)
#
# hndlr -> P[string] = Print this string to chat
# hndlr <- E[string] = Error with string, game finished STATE_FAILED
#
# hdnlr <- D = Game finished STATE_OVER
# hndlr <- DP[index|points] = Player with index, score
# hndlr <- DT[teamindex|points] = Team with index, score

require("coffee-script")
portlist = require("./handlr_portlist")
Futures  = require("futures")
MQ       = require("./handlr_mq_sub")

read_to_newline = (data, cursor) ->
  str = ""
  loop
    break if data[cursor] == "\n"
    str = str + data[cursor]
    cursor = cursor + 1
  return str

ackmsg = (client, mid, data) ->
  debug("sending A" + mid + "#" + data + "\n")
  client.write("A" + mid + "#" + data + "\n")

crunch_data = (client, data) ->
  cursor = 0
  loop
    break if (cursor >= data.length)
    str = read_to_newline(data, cursor)
    res = str.match(/^(\d+);(\d+)#(.+)$/)
    
    debug("Port " + res[1] + " Message number " + res[2] + " is " + res[3])
    msg_port = res[1]
    msg_ind  = res[2]
    msg_body = res[3]
    if(msg_body[0] == 'I')
      ackmsg(client, msg_ind, "I")
    else if(msg_body[0] == 'L')
      ind = msg_body.substring(1)
      debug(ind)
      Futures.sequence()
      .then (next) ->
        portlist.get_port(Number(msg_port), next)
      .then (next, record) ->
        roomdata = record.room
        debug(roomdata.players.length - 1)
        stopnow = 0
        stopnow = 1 if(ind == String(roomdata.players.length - 1))
        ackmsg(client, msg_ind, ("L" + stopnow + "|" + ind + "|" + roomdata.players[ind].steamid + "|2"))
    else
      ackmsg(client, res[2], "U")
    cursor = str.length + 1
      
server = net.createServer (c) ->
  debug('client connected')
  c.setEncoding("utf8")
  c.on 'end', () ->
    debug('Client disconnected')
  c.on 'data', (data) ->
    debug(data)
    crunch_data(c, data)

server.listen 1996, () ->
  debug('server bound')

###
#debug('wopo')
#client = net.connect {port: 8124}, () ->
#  debug('connected to server!')
#  client.write('abcde')
#  setTimeout () ->
#    client.write("fghij")
#  , 1000
#
#client.on 'data', (data) ->
#  console.log(data.toString())
#  client.end()
#
#client.on 'end', () ->
#  console.log('disconnected from server')
###

