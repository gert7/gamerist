source 'https://rubygems.org'
ruby '1.9.3', :engine => 'jruby', :engine_version => '1.7.19'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.10'

# PostgreSQL
group :development, :production do
  gem 'activerecord-jdbcpostgresql-adapter', '1.3.7', require: false
end

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0', require: false

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0', require: false

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0', require: false

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs', require: false
gem 'therubyrhino', platforms: :ruby, require: false

# Use jquery as the JavaScript library
gem 'jquery-rails', require: false

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

gem 'activeadmin', github: 'activeadmin'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Gamerist-specific
gem 'devise', "~> 3.4.1" # 3.2.4
gem 'omniauth'
gem 'omniauth-steam'
gem 'paypal-sdk-rest', require: false # 0.6.1
gem 'geocoder', require: false # 1.2.0

gem 'redis', require: false # 3.0.7
gem 'redis-rails', require: false # 4.0.0
gem 'redis-objects', require: false
gem 'mlanett-redis-lock', require: 'redis-lock'
gem 'rack-cache', require: false
gem 'redis-namespace', require: false
gem 'redis-rack-cache', require: false
gem 'march_hare', require: false # 2.1.2-java

gem 'ejs', require: 'ejs'
gem 'annotate', require: false
gem 'sidekiq', require: false
gem 'sinatra', require: false

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

gem 'puma', '2.11.1', require: false

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# group :development do
#  gem 'spork'
#  gem 'guard-rspec', require: false
# end

group :development, :test do
  gem 'activerecord-jdbcsqlite3-adapter', '1.3.7', require: false
  gem 'rspec', require: false
  gem 'rspec-rails', require: false
  gem 'capybara', require: false
  gem 'factory_girl_rails', require: false
  gem 'coveralls', require: false
  gem 'database_cleaner', require: false
  gem 'mocha', require: false
  gem 'require_all'#, require: false
end

gem 'newrelic_rpm'
