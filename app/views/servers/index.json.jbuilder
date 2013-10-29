json.array!(@servers) do |server|
  json.extract! server, :number, :server_address, :dispatch_address, :dispatch_version
  json.url server_url(server, format: :json)
end
