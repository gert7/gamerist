require Rails.root.join("config", "initializers", "gamerist")
require Rails.root.join("config", "initializers", "geocoder")

def get_continent(countryname)
  i = $gamerist_continentdata["countries"].find_index {|c| c["country"] == countryname }
  return $gamerist_continentdata["countries"][i]["continent"]
end

def fetch_continent_country(ipaddress)
  puts Geocoder.search(ipaddress)
  puts Geocoder.search(ipaddress)[0]
  if(Geocoder.search(ipaddress)[0])
    return (Geocoder.search(ipaddress)[0].country or "Reserved")
  end
  return "Reserved"
end

def fetch_continent(ipaddress)
  reported_country = fetch_continent_country(ipaddress)
  return get_continent(reported_country)
end

