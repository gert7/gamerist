require 'yaml'

$GAMERIST_API_KEYS = YAML.load_file("config/apikeys.yml")

class GameristApiKeys
  def self.get(k)
    puts k.upcase
    puts ENV[k.upcase]
    return (ENV[k.upcase] or $GAMERIST_API_KEYS[k])
  end
end

