require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'omniauth'
require 'config/initializers/apikeys_accessor'

module Gamerist
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.autoload_paths += Dir["#{config.root}/lib/workers/**/"]
    config.eager_load_paths += ["#{Rails.root}/lib"]
    if(Rails.env.production?)
      config.cache_store = :redis_store, 'redis://' + $GAMERIST_API_KEYS["redis_production"] + '/0/cache', { expires_in: 90.minutes }
    else
      config.cache_store = :redis_store, 'redis://' + $GAMERIST_API_KEYS["redis_development"] + '/0/cache', { expires_in: 90.minutes }
    end
    #config.assets.initialize_on_precompile = false
    #config.assets.precompile += %w( active_admin.css active_admin/print.css active_admin.js )
  end
  
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :steam, $GAMERIST_API_KEYS["steam"]
  end
  
  MARGIN_FIXED_RATE = 1
  MARGIN_MULT_RATE  = 1.0
  
  require 'json_vat'
  require 'money'
  require 'money/bank/google_currency'
  require 'config/initializers/gamerist'
  
  Money::Bank::GoogleCurrency.ttl_in_seconds = 600
  Money.default_bank = Money::Bank::GoogleCurrency.new

  @@pointcost = Money.new(1_00, "EUR") # amount is in cents
  
  def self.country(code)
    defaultcountry = $gamerist_countrydata[0]
    puts (($gamerist_countrydata.find {|c| code.to_s == c["threecode"].to_s}) or defaultcountry)
    countryo = (($gamerist_countrydata.find {|c| (code.to_s == c["threecode"].to_s) or (code.to_s == c["twocode"]) }) or defaultcountry)
    puts countryo
    country  = countryo.clone
    
    c = JSONVAT.country(country["twocode"]) or JSONVAT.country(defaultcountry["twocode"])
    country["vat"] = c.rate / 100

    country["masspaycurrency"] = country["currency"]
    country["pointcost"] = @@pointcost.exchange_to(country["currency"].to_sym)
    return country
  end
end

