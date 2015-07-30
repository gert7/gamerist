json.reqid (user_signed_in? ? current_user.id : 0)
json.uniquesignature @uniquesignature
json.prejoindata (user_signed_in? ? @room.prejoindata(current_user) : "NL")
json.personal_messages @room.personal_messages if @room.personal_messages
json.id @room.id
json.state @room.rstate
json.rules @room.srules
json.final_server_address @room.final_server_address
