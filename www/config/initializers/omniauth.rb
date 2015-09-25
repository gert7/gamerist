require "omniauth/strategies/steam"
require "openid/store/filesystem"

api_key = $GAMERIST_API_KEYS["steam"]

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :steam, api_key, :storage => OpenID::Store::Filesystem.new("/tmp")
end

