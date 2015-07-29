require 'yaml'

$gamerist_mapdata     = YAML.load(Rails.root.join("config", "games.yml"))
$gamerist_serverdata  = YAML.load(Rails.root.join("config", "servers.yml"))
$gamerist_countrydata = YAML.load(Rails.root.join("config", "countries.yml"))
$gamerist_continentdata= JSON.parse(File.read(Rails.root.join("config", "continents.json")))

def get_continent(countryname)
  return $gamerist_continentdata["countries"].find_index {|c| c["country"] == countryname }["continent"]
end
