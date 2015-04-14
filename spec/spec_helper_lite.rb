require 'rspec'
require 'simplecov'
require 'coveralls'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'app/admin'
end
Coveralls.wear!
require 'rspec/autorun'
require 'factory_girl_rails'
require 'require_all'
require 'active_record'
require_all File.expand_path '../../app/models', __FILE__

RSpec.configure do |config|
    config.mock_with :mocha
    # config.use_transactional_fixtures = true
    # config.infer_base_class_for_anonymous_controllers = false
    config.treat_symbols_as_metadata_keys_with_true_values = true

      # Run specs in random order to surface order dependencies. If you find an
      # order dependency and want to debug it, you can fix the order by providing
      # the seed, which is printed after each run.
      #     --seed 1234
    config.order = "random"
    #config.include Capybara::DSL
    #config.after(:each) do
    #  counter += 1
    #  if counter > 9
    #    GC.enable
    #    GC.start
    #    GC.disable
    #    counter = 0
    #  end
    #end
    #Rails.cache.clear

    #require 'database_cleaner'
    #DatabaseCleaner[:redis].strategy = :truncation
    
    #config.after(:suite) do
    #  Rails.cache.clear
    #end
end
