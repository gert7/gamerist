# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready () ->
  $("input").parents("#room_playercount label").each () ->
    $(this).css("background-color", "#660")

  $("[checked='checked']").parents("#room_playercount label").each () ->
    $(this).css("background-color", "#990")

  $(".field_bigradio").on 'change', (e) ->
    console.log("changed to " + e.target.value)
    $(this).children(".bigradiobutton").each () ->
      $(this).css("background-color", "#660")
    $(e.target).parent().css("background-color", "#990")


