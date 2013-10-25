require 'em-hiredis'

EM.next_tick do
	redis = EM::Hiredis.connect("redis://127.0.0.1:6379")
	redis.pubsub.subscribe "gamerist_node" do |msg|
		print msg
	end
end
