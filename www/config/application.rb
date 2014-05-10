require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

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


  end
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :steam, $GAMERIST_API_KEYS["steam"]
  end
  
  def country(code)
    case code
    when :EST
      return {
        vat: 0.20,
        compensation: 0.10, # compensate for 10% of VAT
        paypalcurrency: :EUR,
        masspaycurrency: :EUR,
        masspayrate: 0.02,
        masspayfallout: 6.0
      }
    else
      return {
        vat: 0.20,
        compensation: 0.10,
        paypalcurrency: :EUR,
        masspaycurrency: :EUR,
        masspayrate: 0.02,
        masspayfallout: 35.0
      }
    end
  end
  
end
