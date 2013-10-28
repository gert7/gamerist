json.array!(@maps) do |map|
  json.extract! map, :prefix, :name, :game_id
  json.url map_url(map, format: :json)
end
