require 'yaml'

$GAMERIST_API_KEYS = YAML.load_file("config/apikeys.yml")

class GameristApiKeys
  def self.get(k)
    return (ENV[k.upcase] or $GAMERIST_API_KEYS[k])
  end
end

