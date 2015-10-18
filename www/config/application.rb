require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

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
    require "#{config.root}/config/initializers/apikeys_accessor"

    puts config.root
    puts File.join(config.root, "config", "initializers", "apikeys_accessor")
    
    config.autoload_paths += Dir["#{config.root}/lib/workers/**/"]
    config.eager_load_paths += ["#{Rails.root}/lib"]
    if(Rails.env.production?)
      config.cache_store = :redis_store, 'redis://' + GameristApiKeys.get("redis_production") + '/0/cache', { expires_in: 90.minutes }
    else
      config.cache_store = :redis_store, 'redis://' + GameristApiKeys.get("redis_development") + '/0/cache', { expires_in: 90.minutes }
    end
    
    config.active_record.raise_in_transactional_callbacks = true
    #config.assets.initialize_on_precompile = false
    #config.assets.precompile += %w( active_admin.css active_admin/print.css active_admin.js )
  end
end


