msg_body = "DPSTEAM_0:1:WHATEVER|0|&|"

data = {room: players: [{"id":1,"ready":0,"wager":5,"avatar":"http://","steamname":"Hello","team":3,"steamid":"STEAM_0:1:18525940","timeout":1435667836}]}

read_to_character = (data, scursor, br) ->
  str = ""
  cursor = scursor
  console.log(cursor)
  loop
    break if data[cursor] == br
    str = str + data[cursor]
    cursor = cursor + 1
  console.log(data)
  console.log([cursor, str])
  return [cursor + 1, str]

scores = []
pcursor = 2
for i in [1 .. data.room.players.length]
  stido   = read_to_character(msg_body, pcursor, '|')
  pcursor = stido[0]
  stid    = stido[1]
  if(stid == '&') # fewer than playercount players were connected at this time
    break
  scoreo  = read_to_character(msg_body, pcursor, '|')
  pcursor = scoreo[0]
  score   = scoreo[1]
  scores[i] = {"steamid" : stid, "score": score}
kato = '{"protocol_version":1, "type": "playerscores", "id": ' + data.roomid + ', "scores": ' + JSON.stringify(scores) + '}'
console.log(kato)

