$(document).ready () ->
  console.log("yo")
  $.ajax({url: "/accounts.json"}).done (text, textStatus, xhr) ->
    current_user = text
    if(current_user.user_id != "nobody")
      $("#headbar_loggedin_name").html('<a data-method="delete" href="/users/sign_out" rel="nofollow">Sign out</a> | <a data-method="get" href="/accounts">' + current_user.user_id + "</a>")
      $("#headbar_right_content").html("<div id='headbar_points'>" + current_user.total_balance + "</div>")
    else
      $("#headbar_loggedin_name").html('<a data-method="get" href="/users/sign_in" rel="nofollow">Sign in</a>')