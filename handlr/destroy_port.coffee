child_process = require("child_process")
debug         = require("debug")("destroy_port")

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

exports.destroy_port = (port, callback) ->
  debug("Killing process at UDP port " + port)
  spawn_indep("fuser", ["-n", "udp", "-k", port], null, callback)

