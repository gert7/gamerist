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

setContinent = () ->
  $("#room_continent_name").text($("#gamerist_data_continent").val())
  console.dir($("#gamerist_data_continent_available").val())
  if(!$("#gamerist_data_continent_available").val())
   $("#room_continent_name").css("color", "hsl(0, 100%, 55%)")
   $("#room_continent").attr("title", "No server available at this continent!")

trigger_bigradio = (target) ->
  console.dir("triggeré")
  console.dir(target)
  $("#room_playercount").children(".bigradiobutton").each () ->
    $(this).addClass("room_playercount_inactive")
    $(this).removeClass("room_playercount_active")
    $(this).children("input").each () ->
      $(this).prop("checked", false)
  $(target).prop("checked", true)
  $(target).parents(".bigradiobutton").addClass("room_playercount_active")
  $(target).parents(".bigradiobutton").removeClass("room_playercount_inactive")
  console.dir("YES")
  console.dir($('#room_playercount input[type="radio"]:checked').val())

$(document).ready () ->
  $("input").parents("#room_playercount label").each () ->
    $(this).addClass("room_playercount_inactive")
    
  $("#room_playercount label").children("input").each () ->
    $(this).attr("checked", false)
  
  trigger_bigradio($("#room_playercount label").first().children("input"))
  $("#room_playercount label").first().children("input").prop("checked", "checked")
  
  $(".field_bigradio").on 'change', (e) ->
    console.log("changed to " + e.target.value)
    trigger_bigradio(e.target)
  
  $("#room_map").on 'change', (e) ->
    console.dir($("#room_map").find(":selected").text())
    if($("#room_map").find(":selected").text().substring(0, 4) == "ctf_")
      $(".bigradiobutton").each () ->
        if($(this).children("input").val() > 16)
          $(this).css("display", "none")
          if($(this).children("input").attr("checked"))
            trigger_bigradio($("#room_playercount input").first())
        else
          $(this).css("width", "50%")
    else
      $(".bigradiobutton").each () ->
        $(this).css("display", "inline-block")
        $(this).css("width", "25%")
  
  setTimeout(setContinent, 100)
  
