require 'simplecov'
require 'coveralls'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'app/admin'
end
Coveralls.wear!('rails')

#require 'spork'

# Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'capybara/rspec'
  require 'capybara/rails'
  require 'rspec/autorun'
  require 'factory_girl_rails'
  require "rails/application"
#  Spork.trap_method(Rails::Application, :reload_routes!)
  
  require File.dirname(__FILE__) + "/../config/environment.rb"

    # Requires supporting ruby files with custom matchers and macros, etc,
    # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

    # Checks for pending migrations before tests are run.
    # If you are not using ActiveRecord, you can remove this line.
  ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)
    # Don't need passwords in test DB to be secure, but we would like 'em to be
    # fast -- and the stretches mechanism is intended to make passwords
    # computationally expensive.
  module Devise
    module Models
      module DatabaseAuthenticatable
        protected

        def password_digest(password)
          password
        end
      end
    end
  end
  Devise.setup do |config|
    config.stretches = 0
  end

  counter = -1
  RSpec.configure do |config|
    config.mock_with :mocha
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = false
    config.treat_symbols_as_metadata_keys_with_true_values = true

      # Run specs in random order to surface order dependencies. If you find an
      # order dependency and want to debug it, you can fix the order by providing
      # the seed, which is printed after each run.
      #     --seed 1234
    config.order = "random"
    config.include Capybara::DSL
    #config.after(:each) do
    #  counter += 1
    #  if counter > 9
    #    GC.enable
    #    GC.start
    #    GC.disable
    #    counter = 0
    #  end
    #end

    require 'database_cleaner'
    #DatabaseCleaner[:redis].strategy = :truncation
    
    DatabaseCleaner.strategy = :truncation
    config.before(:each) do
      Rails.cache.clear
      DatabaseCleaner.clean
    end
    
    config.include Warden::Test::Helpers
    config.before(:suite) do
      Warden.test_mode!
    end
    Gamerist::Application.config.session_store :cookie_store,
      key: '_gamerist_session',
      domain: :all
  end
#end

#Spork.each_run do
  #class ActiveRecord::Base
  #  mattr_accessor :shared_connection
  #  @@shared_connection = nil

  #  def self.connection
  #    @@shared_connection || retrieve_connection
  #  end
  #end

  # Forces all threads to share the same connection. This works on
  # Capybara because it starts the web server in a thread.
  #ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

  # This code will be run each time you run your specs.
  #load "#{Rails.root}/config/routes.rb" 
  #FactoryGirl.reload
  # reload all the models
  #Dir["#{Rails.root}/app/models/**/*.rb"].each do |model|
  #  load model
  #end
#end
