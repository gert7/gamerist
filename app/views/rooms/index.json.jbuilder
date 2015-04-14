json.array!(@rooms) do |room|
  json.extract! room, :owner, :game_id, :ruleset_id, :state, :server_id
  json.url room_url(room, format: :json)
end
