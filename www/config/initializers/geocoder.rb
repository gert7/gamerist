require "geocoder"

Geocoder.configure(ip_lookup: :telize)
Geocoder.configure(:cache => Redis.new)

