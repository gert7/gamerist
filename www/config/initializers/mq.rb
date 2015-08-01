require 'config/initializers/apikeys_accessor'
require 'config/initializers/gamerist'
require 'bunny'

$bunny = Bunny.new
$bunny.start

ch = $bunny.create_channel
puts "Using exchange gamerist.topic" + (Rails.env.test? ? "test" : "")
x  = ch.direct("gamerist.direct" + (Rails.env.test? ? "test" : ""))

servers = $gamerist_serverdata["servers"]

# Manage the upstream wooooo
ch.queue("gamerist.dispatch.upstream", durable: true).subscribe do |delivery_info, properties, payload|
  require 'json'
  jdata = JSON.parse payload
  puts jdata
  if(jdata["protocol_version"].to_i == 1)
    case jdata["type"]
    when "creating" # preliminary confirmation
    when "pcanceled" # canceled by Rails
    when "heartbeat" # node is responsive
    when "serverstarted" # official confirmation from inside the gameserver
      ip = $gamerist_serverdata["servers"].select {|v| v["name"] == jdata["server"]}[0]["ip"]
      Room.new(id: jdata["id"]).add_running_server({"servername" => jdata["server"], "ip" => ip, "port" => jdata["port"]})
    when "teamwin" # team wins
    when "playerscores" # player score data
    when "servererror" # server encountered an error
    else
    end
  end
end

module DispatchMQ
  require("config/initializers/mq")
  def self.send_room_requests(room)
    require "jbuilder"
    roomrules = room.srules
    roomid    = room.id
    
    ch = $bunny.create_channel
    x  = ch.direct("amq.direct")
    
    servers = $gamerist_serverdata["servers"]
    region  = roomrules["server_region"]
    
    req = Jbuilder.new do |json|
      json.protocol_version 1
      json.id roomid
      json.roomdata roomrules
      json.type "spinup"
      json.timeout Time.now.to_i + 10
    end
    
    puts req.target!
    servers.select {|v| v["region"] == region }.each do |v|
      puts "Pushing message to gamerist.dispatch.down." + v["name"]
      ch.queue("gamerist.dispatch.down." + v["name"], durable: true).bind(x, routing_key: "gamerist.dispatch.down." + v["name"])
      x.publish(req.target!, routing_key: "gamerist.dispatch.down." + v["name"])
    end
  end
  
  def self.send_room_cancel(roomid, servername)
    ch = $bunny.create_channel
    x  = ch.direct("amq.direct")
    
    req = Jbuilder.new do |json|
      json.protocol_version 1
      json.id roomid
      json.type "cancel"
    end
    
    ch.queue("gamerist.dispatch.down." + servername, durable: true).bind(x, routing_key: "gamerist.dispatch.down." + servername)
    x.publish(req.target!, routing_key: "gamerist.dispatch.down." + servername)
  end
end

require "config/initializers/redis"

#if Rails.env.test?
#  User.destroy_all
#  u = User.new(email: "ver@ver.com", password: "dododongo1")
#  (u.steamid = Steamid.new(steamid: "vanwe98wn38328ng2")).save!
#  u.save!
#  r = Room.new(game: "team fortress 2", map: "ctf_2fort", playercount: 16, wager: 5, server: "centurion")
#  r.save!
#  Transaction.make_transaction(user_id: u.id, amount: 15, state: Transaction::STATE_FINAL, kind: Transaction::KIND_PAYPAL, detail: 12)
#  r.append_player! u
#  DispatchMQ::produce_room(r)
#end

