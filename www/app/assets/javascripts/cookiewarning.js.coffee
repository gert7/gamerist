$(document).ready () ->
  if(getCookie("gameristcookieapproval") != "approved")
    askCookieApproval()

getCookie = (cn) ->
  cookies = document.cookie.split(";")
  for c in cookies
    partial = c.split("=")
    if partial[0] == cn
      return partial[1]
  return ""

appendCallbacksCookie = () ->
  $("#cookie_warning_agree").click ->
    console.dir($("#cookie_warning_outer"))
    $("#cookie_warning_outer").animate({marginTop: "-112px"}, 1000, () ->
      $("#cookie_warning_outer").css("display", "none")
    )
    document.cookie = "gameristcookieapproval=approved"
  $("#cookie_warning_disagree").click ->
    window.location = "http://www.duckduckgo.com"

askCookieApproval = () ->
  $("#header").before('<div id="cookie_warning_outer"><div id="cookie_warning"><div id="cookie_warning_text">This website uses browser cookies to improve your experience</div><button id="cookie_warning_agree">DISMISS</button><button id="cookie_warning_disagree">LEAVE</button></div></div>')
  setTimeout(appendCallbacksCookie, 2)
  
