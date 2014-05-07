#conn = MarchHare.connect
#ch = conn.create_channel
#q  = ch.queue("", :auto_delete => true)
#x  = ch.topic("boopsi", :auto_delete => true)
#q.bind(x, routing_key: "amq.rabbitmq.trace")

#  q.subscribe do |metadata, payload|
#    puts "Received #{payload}"
#  end

#  x.publish("Hello!")

