$(document).ready () ->
  if(getCookie("gameristcookieapproval") != "approved")
    askCookieApproval()

getCookie = (cn) ->
  console.dir(document.cookie)
  cookies = document.cookie.split(";")
  for c in cookies
    partial = c.split("=")
    spart   = ""
    if partial[0][0] == " "
      console.log("Partial starts with space: " + partial[0])
      spart = partial[0].substring(1)
    else
      spart = partial[0]
    if spart == cn
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
    window.location = "https://www.duckduckgo.com"

askCookieApproval = () ->
  $("#header").before('<div id="cookie_warning_outer"><div id="cookie_warning"><div id="cookie_warning_text">This website uses browser cookies to improve your experience</div><button id="cookie_warning_agree">I UNDERSTAND</button><button id="cookie_warning_disagree">LEAVE</button></div></div>')
  setTimeout(appendCallbacksCookie, 2)
  
