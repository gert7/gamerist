require "geocoder"
require Rails.root.join("config", "initializers", "redis")

Geocoder.configure(ip_lookup: :google, use_https: true)
Geocoder.configure(:cache => $redis)

