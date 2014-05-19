require "sidekiq"
require "sidekiq/activerecord"
require 'factory_girl'
require 'database_cleaner'
require 'support'

RSpec.configure do |config|
  config.alias_example_to :expect_it

  # config.full_backtrace = true

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  config.expect_with :rspec do |config|
    config.syntax = :expect
  end

  config.include FactoryGirl::Syntax::Methods # Don't need to write FactoryGirl.create => create

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

