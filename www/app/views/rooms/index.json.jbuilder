@roomsi = @rooms.map {|v| JSON.parse(v)}
json.rooms @roomsi

json.total_size @roomslength

