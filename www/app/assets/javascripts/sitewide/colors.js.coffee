$(document).ready () ->
  changeColor = () ->
    $(".saturatedBackground").each () -> $(this).animate({"background-color": "#FF5D00"})
    $(".saturatedBackground2").each () -> $(this).animate({"background-color": "#FF5D00"})
    $(".saturatedText").each () -> $(this).animate({"color": "#FF5D00"})
    $(".saturatedBackgroundDim").each () -> $(this).animate({"background-color": "#DD5000"})

