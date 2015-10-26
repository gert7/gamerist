# Create an actual server with the given settings
require("coffee-script")
portlist      = require("./handlr_portlist")
child_process = require("child_process")
fs            = require("fs")
Futures       = require("futures")
debug         = require("debug")("spinup")
path          = require("path")
destroy_port  = require("./destroy_port")

Config        = require("./handlr_config").conf

spawn_indep_async = (cmd, args, id, closecallback) ->
  if !Config.travismode
    proc = child_process.spawn(cmd, args, {detached: true})
  (closecallback || ->)()

udp_getport = (port, errcallback) ->
  dgram  = require("dgram")
  server = dgram.createSocket("udp4")
  server.on("error", (err) ->
    debug("UDP Port " + port + " is already bound: \n" + err.stack)
    server.close()
    errcallback(true)
  )
  server.on("listening", () ->
    debug("UDP Port " + port + " is not yet bound")
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
      destroy_port.destroy_port(port, next)
    else
      next()
  .then (next) ->
    srcfolder = settings.game
    ipath     = path.resolve("../steamcmd", srcfolder, "srcds_run")
    debug(ipath)
    spawn_indep_async(ipath, ["-game", settings.subname, "+map", settings.map, "+playercount", settings.playercount, "-port", port, "+exec", "server.cfg", "-norestart"], room, next)
  .then (next) ->
    errcallback()

spin_up = (roomid, room, errcallback) ->
  vport = 0
  
  Futures.sequence()
  .then (next) ->
    portlist.get_port_by_id(roomid, next)
  .then (next, record) ->
    if record
      errcallback(true, -1)
      debug("Room with this ID already exists")
    else
      next()
  .then (next) ->
    portlist.remember_a_port(roomid, room, next)
  .then (next, port, err) ->
    vport = port
    if port != 0
      gamename = ""
      subname  = ""
      debug(room)
      if room.game == "team fortress 2" then 
        gamename = "tf"
        subname  = "tf"
      if room.game == "counter strike source" then 
        gamename = "css"
        subname  = "cstrike"
      spin_up_port(port, roomid, {game: gamename, subname: subname, map: room.map, playercount: room.playercount}, next)
    else
      errcallback(true, vport)
  .then ->
    errcallback(false, vport)

exports.spin_up = spin_up

