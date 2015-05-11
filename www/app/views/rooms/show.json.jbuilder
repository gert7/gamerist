json.reqid (user_signed_in? ? current_user.id : 0)
json.id @room.id
json.state @room.state
json.rules @room.srules

