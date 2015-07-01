child_process = require("child_process")
debug         = require("debug")("destroy_port")
Futures       = require("futures")

spawn_indep = (cmd, args, id, closecallback) ->
  out = err =
  if id
    out = fs.openSync('./output_' + id + '.log', 'a')
    err = fs.openSync('./output_' + id + '.log', 'a')
  else
    out = 'ignore'
    err = 'ignore'
  child = child_process.spawn(cmd, args, {stdio: [ 'ignore', out, err ]})
  child.on("close", (closecallback || ->))

exports.destroy_port = (port, callback) ->
  Futures.sequence()
  .then (next) ->
    spawn_indep("fuser", ["-n", "udp", "-k", port], null, next)
  .then (next) ->
    debug("Destroyed process on port " + port)
    (callback || ->)()

exports.destroy_port_async = (port, endcallback) ->
  spawn_indep("fuser", ["-n", "udp", "-k", port], null, endcallback)
  debug("Destroying process on port " + port + "...")
  (callback || ->)()
  
