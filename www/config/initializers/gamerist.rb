require 'yaml'

$gamerist_mapdata = YAML.load(Rails.root.join("config", "games.yml"))

