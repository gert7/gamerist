require "march_hare"

conn = MarchHare.connect

ch = conn.create_channel
q  = ch.queue("to_rails", :auto_delete => true)
x  = ch.direct("tx")
q.bind("tx")

q.subscribe do |metadata, payload|
  puts "Received #{payload}"
end

x.publish("Hello!")

