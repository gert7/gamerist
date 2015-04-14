require 'yaml'

$gamerist_mapdata = YAML.load(Rails.root.join("config", "games.yml"))
$gamerist_serverdata = YAML.load(Rails.root.join("config", "servers.yml"))

