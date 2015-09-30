require "paypal-sdk-rest"
require 'config/initializers/apikeys_accessor'

PayPal::SDK::REST.set_config(
  :mode => "sandbox",
  :client_id => GameristApiKeys.get("paypal_clid"),
  :client_secret => GameristApiKeys.get("paypal_clsecret"))

$PAYPAL_SDK_RETURN_HOSTNAME = GameristApiKeys.get("paypal_return_hostname")

