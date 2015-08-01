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

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

read_to_character = (data, scursor, br) ->
  str = ""
  cursor = scursor
  loop
    break if data[cursor] == br
    str = str + data[cursor]
    cursor = cursor + 1
  return [cursor + 1, str]
  
read_to_newline = (data, cursor) ->
  return read_to_character(data, cursor, '\n')[1]

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
    msg_port = Number(res[1])
    msg_ind  = res[2]
    msg_body = res[3]
    if(msg_body[0] == 'I')
      Futures.sequence()
      .then (next) ->
        portlist.remove_timeout_ports(next)
      .then (next) ->
        portlist.get_port(msg_port, next)
      .then (next, record) ->
        MQ.send_upstream('{"protocol_version":1, "server": "' + Config.selfname + '", "type": "serverstarted", "port": "' + msg_port + '", "id": ' + record.roomid + '}')
      ackmsg(client, msg_ind, "I")
    else if(msg_body[0] == 'L')
      ind = msg_body.substring(1)
      debug(ind)
      Futures.sequence()
      .then (next) ->
        portlist.remove_timeout_ports(next)
      .then (next) ->
        portlist.get_port(msg_port, next)
      .then (next, record) ->
        if record
          roomdata = record.room
          debug(roomdata.players.length - 1)
          stopnow = 0
          stopnow = 1 if(ind == String(roomdata.players.length - 1))
          ackmsg(client, msg_ind, ("L" + stopnow + "|" + ind + "|" + roomdata.players[ind].steamid + "|" + roomdata.players[ind].team))
    else if(msg_body[0] == 'H')
      Futures.sequence()
      .then (next) ->
        portlist.heartbeat_port(msg_port, next)
      .then (next, err) ->
        if err
          debug("Server on " + msg_port + "has TIMED OUT!!!")
        else
          ackmsg(client, msg_ind, "H")
          debug("Server on " + msg_port + " has heartbeat")
    else if(msg_body[0] == 'D')
      if(msg_body[1] == 'T')
        Futures.sequence()
        .then (next) ->
          portlist.get_port(msg_port, next)
        .then (next, data) ->
          debug(data)
          MQ.send_upstream('{"protocol_version":1, "type": "teamwin", "id": ' + data.roomid + ', "winningteam": ' + (msg_body[2]) + ', "losingteam": ' + (msg_body[3]) + '}')
          ackmsg(client, msg_ind, "A")
      else if (msg_body[1] == 'P')
        scores = []
        Futures.sequence()
        .then (next) ->
          portlist.get_port(msg_port, next)
        .then (next, data) ->
          debug(data)
          pcursor = 2
          for i in [0 .. (data.room.players.length - 1)]
            stido   = read_to_character(msg_body, pcursor, '|')
            pcursor = stido[0]
            stid    = stido[1]
            if(stid == '&') # fewer than playercount players were connected at this time
              break
            scoreo  = read_to_character(msg_body, pcursor, '|')
            pcursor = scoreo[0]
            score   = scoreo[1]
            scores[i] = {"steamid" : stid, "score": score}
          kato = '{"protocol_version":1, "type": "playerscores", "id": ' + data.roomid + ', "scores": ' + JSON.stringify(scores) + '}'
          debug(kato)
          MQ.send_upstream(kato)
          ackmsg(client, msg_ind, "A")
    else if(msg_body[0] == 'E')
      errno = msg_body.match(/^E(\d+)$/)[1]
      seq = Futures.sequence()
      .then (next) ->
        portlist.get_port(msg_port, next)
      .then (next, data) ->
        MQ.send_upstream('{"protocol_version":1, "type": "servererror", "id": ' + data.roomid + ', "errno": ' + errno + '}')
        # don't bother acking, server's already killed
    else
      ackmsg(client, res[2], "T")
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

