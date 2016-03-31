dbi   = @database << time_ago_in_words(Time.at(@database[1].to_i).to_datetime)
redi  = @redis << time_ago_in_words(Time.at(@redis[1].to_i).to_datetime)
mqsti = @mqst << time_ago_in_words(Time.at(@mqst[0].split("@")[1].to_i).to_datetime)
if(mqsti[0].start_with?("self test completed @"))
  mqsti[0] = "ONLINE"
end

statusi = @server_status.map do |x|
  x["timeago"] = time_ago_in_words(Time.at(x["timestamp"].to_i).to_datetime)
end

json.database dbi
json.redis redi
json.mq mqsti
json.servers @server_status
