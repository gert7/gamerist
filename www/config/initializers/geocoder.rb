require "geocoder"
require Rails.root.join("config", "initializers", "redis")

Geocoder.configure(ip_lookup: :freegeoip)
Geocoder.configure(:cache => $redis)

# Provide a hardcoded ip of 1.2.3.4 when in developmnt/test and the ip address resolves as localhost
if %w(development test).include? Rails.env
  module Geocoder
    module Request
      def geocoder_spoofable_ip_with_localhost_override
        ip_candidate = geocoder_spoofable_ip_without_localhost_override
        if ip_candidate == '127.0.0.1'
          '176.46.75.247'
        else
          ip_candidate
        end
      end
      alias_method_chain :geocoder_spoofable_ip, :localhost_override
    end
  end
end

