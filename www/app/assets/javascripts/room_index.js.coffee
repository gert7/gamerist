ROOM_DELAY = 8000

updateRoomIndex = (nexttime) ->
  $.get("/rooms.json", formatPage)
  ROOM_DELAY = nexttime or ROOM_DELAY

formatPage = (data) ->
  $("#roomslist_pagination").html("")
  for i in [0...data.total_size]
    xroom = data.rooms[i]
    redplayers = xroom.rules.players.filter((v) -> v.team == 2).length
    bluplayers = xroom.rules.players.filter((v) -> v.team == 3).length
    tc = xroom.rules.playercount / 2
    $("#roomslist_pagination").append('<a href="/rooms/' + xroom.id + '"><div class="pag_room"><div class="pag_room_left"><div class="pag_room_id">Room #' + xroom.id + '</div><div class="pag_room_region">' + xroom.rules.server_region + '</div></div><div class="pag_room_middle"><div class="pag_room_wager">' + xroom.rules.wager + '</div><div class="pag_room_map">' + xroom.rules.map + '</div></div><div class="pag_room_red">' + redplayers + '/' + tc + ' players</div><div class="pag_room_blu"> ' + bluplayers + '/' + tc + ' players</div></div></a>')
  if(data.total_size == 0)
    $("#roomslist_pagination").html('<div style="background:white"><br/><br/><center>There are no active rooms!</center><br/><br/></div>')
  setTimeout(updateRoomIndex, ROOM_DELAY)

$(document).ready ->
  if $("#roomslist_pagination").length
    updateRoomIndex()
  
  $("#roomslist_new_room_button").click () ->
    window.location = "/rooms/new"
