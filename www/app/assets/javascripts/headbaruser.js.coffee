$(document).ready () ->
  console.log("yo")
  accgrab = $.ajax({url: "/accounts.json"})
  accgrab.done (text, textStatus, xhr) ->
    current_user = text
    console.dir(current_user)
    if(current_user.user_id and current_user.user_id != "nobody")
      $("#headbar_loggedin_name").html('<a data-method="delete" href="/users/sign_out" rel="nofollow">Sign out</a> | <a data-method="get" href="/accounts">' + current_user.user_id + "</a>")
      $("#headbar_right_content").html("<div id='headbar_points'>" + current_user.total_balance + "</div> | <a href='/account/unfreeze'>Current game</a>")
      $("#gamerist_data_country").val(current_user.country)
      $("#gamerist_data_continent").val(current_user.continent)
      $("#gamerist_data_continent_available").val(current_user.continent_available)
      console.dir(current_user)
      console.log("flop")
    else if(current_user.user_id == "nobody")
      $("#headbar_loggedin_name").html('<a data-method="get" href="/users/sign_in" rel="nofollow">Sign in</a>')
  accgrab.error (jq) ->
  	if jq.status == 401
	  	$("#headbar_loggedin_name").html('<a data-method="get" href="/users/sign_in" rel="nofollow">Sign in</a>')
      
