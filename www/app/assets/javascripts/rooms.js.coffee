formatPage = (data) ->
  for i in [0..(data.total_size - 1)]
    xroom = data.rooms[i]
    redplayers = xroom.rules.players.filter((v) -> v.team == 2).length
    bluplayers = xroom.rules.players.filter((v) -> v.team == 3).length
    tc = xroom.rules.playercount / 2
    $("#roomslist_pagination").append('<a href="/rooms/' + xroom.id + '"><div class="pag_room"><div class="pag_room_left"><div class="pag_room_id">Room #' + xroom.id + '</div><div class="pag_room_region">' + xroom.rules.server_region + '</div></div><div class="pag_room_middle"><div class="pag_room_wager">' + xroom.rules.wager + '</div><div class="pag_room_map">' + xroom.rules.map + '</div></div><div class="pag_room_red">' + redplayers + '/' + tc + ' players</div><div class="pag_room_blu"> ' + bluplayers + '/' + tc + ' players</div></div></a>')

$(document).ready ->
  if $("#roomslist_pagination").length
    $.get("/rooms.json", formatPage)

trigger_bigradio = (target) ->
  $("#room_playercount").children(".bigradiobutton").each () ->
    $(this).css("background-color", "hsl(65,50%,50%)")
  $(target).parent().css("background-color", "hsl(65,100%,50%)")

$(document).ready () ->
  $("input").parents("#room_playercount label").each () ->
    $(this).css("background-color", "hsl(65,50%,50%)")
    
  $("#room_playercount label").children("input").each () ->
    $(this).attr("checked", false)
  
  trigger_bigradio($("#room_playercount label").first().children("input"))

  $(".field_bigradio").on 'change', (e) ->
    console.log("changed to " + e.target.value)
    trigger_bigradio(e.target)

