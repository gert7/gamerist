$redis = EM::Hiredis.new(:host => 'localhost', :port => 6379)
$redis.subscribe('gamerist_node') do |on|   
  on.message do |channel, msg|
	
  end 
end
