require "geocoder"
require Rails.root.join("config", "initializers", "redis")

Geocoder.configure(ip_lookup: :telize)
Geocoder.configure(:cache => $redis)

