require 'config/initializers/apikeys_accessor'
require 'config/initializers/gamerist'
require 'bunny'

$bunny = Bunny.new
$bunny.start

ch = $bunny.create_channel
x  = ch.topic("gamerist.topic")
servers = $gamerist_serverdata["servers"]

# Manage the upstream wooooo
ch.queue("gamerist.dispatch.upstream").bind(x, routing_key: "gamerist.dispatch.up.*").subscribe do |delivery_info, properties, payload|
  require 'json'
  jdata = JSON.parse payload
  if(jdata["protocol_version"].to_i == 1)
    
  end
end

module DispatchMQ
  def self.produce_room(roomrules)
    require "jbuilder"
    ch = $bunny.create_channel
    x  = ch.topic("gamerist.topic")
    servers = $gamerist_serverdata["servers"]
    servername = roomrules["server"] or servers[0]["name"]
    
    req = Jbuilder.new do |json|
      json.protocol_version 1
      json.roomdata do
        json.players(roomrules["players"]) do |player|
          usr = User.new()
        end
      end
    end
    
    puts req.target!
    #x.publish(req.to_s, routing_key: "gamerist.dispatch.down." + servername)
  end
end

DispatchMQ::produce_room({"hey" => "haiao", "data" => ["some", "array"]}, "trivium")

