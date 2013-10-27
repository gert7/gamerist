json.array!(@games) do |game|
  json.extract! game, :prettyname, :enum
  json.url game_url(game, format: :json)
end
