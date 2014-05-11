require "paypal-sdk-rest"

PayPal::SDK::REST.set_config(
  :mode => "sandbox",
  :client_id => "AV4lGBB0twjUtkL7uJ2fkUjtUznWzb9QyexJeaLJV9AXKcRQ5n3F00tJdly6",
  :client_secret => "EAbDQxAKVcIew8bnIShscCU4-xqE3lm-ckRu1fN8pIRwjSj4fKkPFwVcC4cz")

def paypal_payment_callback_route(r)
  request.host + request.port
end

