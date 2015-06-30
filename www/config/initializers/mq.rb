require 'config/initializers/apikeys_accessor'
require 'config/initializers/gamerist'
require 'bunny'

$bunny = Bunny.new
$bunny.start

ch = $bunny.create_channel
puts "Using exchange gamerist.topic" + (Rails.env.test? ? "test" : "")
x  = ch.topic("gamerist.topic" + (Rails.env.test? ? "test" : ""))
servers = $gamerist_serverdata["servers"]

# Manage the upstream wooooo
ch.queue("gamerist.dispatch.upstream", durable: true).bind(x, routing_key: "gamerist.dispatch.up.*").subscribe do |delivery_info, properties, payload|
  require 'json'
  jdata = JSON.parse payload
  if(jdata["protocol_version"].to_i == 1)
    
  end
end

# TEST ONLY
# Hijack the downstream for testing
#if(Rails.env.test?)
  #ch.queue("gamerist.dispatch.down.centurion").bind(x, routing_key: "gamerist.dispatch.down.centurion").subscribe do |delivery_info, properties, payload|
    #require 'json'
    #jdata = JSON.parse payload
    #if(jdata["protocol_version"].to_i == 1)
      
    #end
  #end
#end

module DispatchMQ
  def self.produce_room(room)
    require "jbuilder"
    roomrules = room.srules
    roomid    = room.id
    
    ch = $bunny.create_channel
    x  = ch.topic("gamerist.topic" + (Rails.env.test? ? "test" : ""))
    servers    = $gamerist_serverdata["servers"]
    servername = roomrules["server"] or servers[0]["name"]
    
    req = Jbuilder.new do |json|
      json.protocol_version 1
      json.roomdata roomrules
    end
    
    puts req.target!
    puts "Pushing message to gamerist.dispatch.down." + servername
    puts x.publish(req.target!, routing_key: "gamerist.dispatch.down." + servername)
  end
end

require "config/initializers/redis"

if Rails.env.test?
  User.destroy_all
  u = User.new(email: "ver@ver.com", password: "dododongo1")
  (u.steamid = Steamid.new(steamid: "vanwe98wn38328ng2")).save!
  u.save!
  r = Room.new(game: "team fortress 2", map: "ctf_2fort", playercount: 16, wager: 5, server: "centurion")
  r.save!
  Transaction.make_transaction(user_id: u.id, amount: 15, state: Transaction::STATE_FINAL, kind: Transaction::KIND_PAYPAL, detail: 12)
  r.append_player! u
  DispatchMQ::produce_room(r)
end

