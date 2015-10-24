$(document).ready () ->
  if($("#fg_slideshow").length)
    smode = 0
    smodeCall = () ->
      smode++
      $("#fg_slideshow_icon").animate({'background-position': '-=52px'}, 1000)
      $("#fg_slideshow_image").animate({'background-position': '-=355px'}, 1000)
      $("#fg_slideshow_text_inner").animate({'boxShadow': '-4px 4px #b8a759'}, 1000)
      if (smode % 2 == 1)
        $("#fg_slideshow_text_inner_content1").fadeOut()
        $("#fg_slideshow_text_inner_content2").fadeIn()
      else
        $("#fg_slideshow_text_inner_content1").fadeIn()
        $("#fg_slideshow_text_inner_content2").fadeOut()
    setInterval(smodeCall, 5000)  
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
  
