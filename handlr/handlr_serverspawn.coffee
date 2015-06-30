# Create an actual server with the given settings
require("coffee-script")
portlist      = require("./handlr_portlist")
child_process = require("child_process")
fs            = require("fs")
Futures       = require("futures")
debug         = require("debug")("spinup")

spawn_indep = (cmd, args, id, closecallback) ->
  out = err =
  if id
    out = fs.openSync('./output_' + id + '.log', 'a')
    err = fs.openSync('./output_' + id + '.log', 'a')
  else
    out = 'ignore'
    err = 'ignore'
  child = child_process.spawn(cmd, args, {detached: true, stdio: [ 'ignore', out, err ]})
  child.on("close", (closecallback || ->))

udp_getport = (port, errcallback) ->
  dgram  = require("dgram")
  server = dgram.createSocket("udp4")
  server.on("error", (err) ->
    debug("server error:\n" + err.stack)
    server.close()
    errcallback(true)
  )
  server.on("listening", () ->
    debug("server listening ")
    server.close()
    errcallback(false)
  )
  server.bind(27015)

spin_up_port = (port, room, settings, errcallback) ->
  seq = Futures.sequence()
  seq
  .then (next) ->
    debug("Checking if port " + port + " is available...")
    udp_getport(port, next)
  .then (next, err) ->
    debug(err)
    if err == true
      debug("Port " + port + " already in use!!")
      debug("Attempting to destroy process...")
      spawn_indep("fuser", ["-n", "udp", "-k", port], null, next)
    else
      next()
  .then (next) ->
    srcfolder = settings.game
    spawn_indep("../steamcmd/" + srcfolder + "/srcds_run", ["-game", settings.game, "+map", settings.map, "+playercount", settings.playercount, "-port", port], room)
    portlist.remember_port(port, room)
    udp_getport(port, next)
  .then (next, err) ->
    errcallback(err)

spin_up = (roomid, room, errcallback) ->
  Futures.sequence()
  .then (next) ->
    remember_a_port(roomid, room, next)
  .then (next, port, err) ->
    if port != 0
      gamename = ""
      if room.roomdata.game == "team fortress 2" then gamename = "tf"
      spin_up_port(port, roomid, {game: gamename, map: room.roomdata.map, playercount: room.roomdata.playercount}, next)
    else
      errcallback(true)
  .then ->
    errcallback(false)

exports.spin_up = spin_up

