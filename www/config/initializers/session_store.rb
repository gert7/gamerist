# Be sure to restart your server when you modify this file.

require 'redis-rails'

Rails.application.config.session_store :cookie_store, key: '_gamerist_session'

if Rails.env.development?
  Gamerist::Application.config.session_store :redis_store, servers: 'redis://localhost:6379/0/cache'
elsif Rails.env.test?
  Gamerist::Application.config.session_store :cookie_store,
                                         key: '_gamerist_session',
                                         domain: :all
end
