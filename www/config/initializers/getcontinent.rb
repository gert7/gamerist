require "config/initializers/gamerist"

def get_continent(countryname)
  i = $gamerist_continentdata["countries"].find_index {|c| c["country"] == countryname }
  return $gamerist_continentdata["countries"][i]["continent"]
end

def fetch_continent_country(ipaddress)
  return (Geocoder.search(ipaddress)[0].country or "Reserved")
end

def fetch_continent(ipaddress)
  require "geocoder"
  Geocoder.configure(ip_lookup: :telize)
  Geocoder.configure(:cache => Redis.new)
  reported_country = fetch_continent_country(ipaddress)
  return get_continent(reported_country)
end

