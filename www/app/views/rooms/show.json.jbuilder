json.reqid (user_signed_in? ? current_user.id : 0)
json.uniquesignature @uniquesignature
json.prejoindata (user_signed_in? ? @room.prejoindata(current_user, @user_region) : "NL")
json.personal_messages JSON.parse(@room.personal_messages_for(current_user.id)) if @room.personal_messages_for(current_user.id)
json.id @room.id
json.state @room.rstate
json.rules @room.sanitized_srules(current_user)
json.final_server_address @room.final_server_address
