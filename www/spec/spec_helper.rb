require 'coveralls'
Coveralls.wear!('rails')

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'
require 'rspec/autorun'
require 'factory_girl_rails'
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

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
  config.order = "random"
  config.include Capybara::DSL
  config.after(:each) do
    counter += 1
    if counter > 9
      GC.enable
      GC.start
      GC.disable
      counter = 0
    end
  end

  config.after(:suite) do
    counter = 0
  end
end

