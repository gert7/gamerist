require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

# Calculating a wager:
#
# Where final wager (W) is 100
#
# losers give away:
# 100 - [W * VAT compensation = 10] - [W * 1% persistence bonus] = 89 points
#
# .'. winners receive (at 1:2 winnings): 189 points
#
# losers receive: persistence bonus
#
# where:
#  -VAT compensation is applied to the subtotal when adding funds
#  -persistence bonus is given to losers who have remained until
#   the end of the game
#

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
    provider :steam
  end
    
  def api_keys
    require 'yaml'
    YAML::load_file("apikeys.yml")
  end
    
  # when adding unrealized funds,
  # the subtotal is reduced by the
  # compensation lever to compensate
  # for VAT by some degree
  #
  # this money is then removed from
  # winnings
  #
  # 99 + (99 * (VAT[.2] - VAT * TCR[.5])) = €108.90 for 100 points
  # instead of €118.80
  #
  # this can be used to alleviate player losses
  # by lowering them
  
  # country-specifics
  
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
