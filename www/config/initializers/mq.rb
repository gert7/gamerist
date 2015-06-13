require 'config/initializers/apikeys_accessor'
require 'config/initializers/gamerist'
require 'bunny'

$bunny = Bunny.new
$bunny.start

ch = $bunny.create_channel
x  = ch.topic("gamerist.topic" + (Rails.env.test? ? "test" : ""))
servers = $gamerist_serverdata["servers"]

# Manage the upstream wooooo
ch.queue("gamerist.dispatch.upstream").bind(x, routing_key: "gamerist.dispatch.up.*").subscribe do |delivery_info, properties, payload|
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
    x  = ch.topic("gamerist.topic")
    servers = $gamerist_serverdata["servers"]
    servername = roomrules["server"] or servers[0]["name"]
    
    req = Jbuilder.new do |json|
      json.protocol_version 1
      json.roomdata roomrules
    end
    
    puts req.target!
    x.publish(req.target!, routing_key: "gamerist.dispatch.down." + servername)
  end
end

class DummyRoom
  def srules
    return {"server" => "centurion", "message" => "Helou Wirld!"}
  end
  
  def id
    11
  end
end

DispatchMQ::produce_room(DummyRoom.new)

