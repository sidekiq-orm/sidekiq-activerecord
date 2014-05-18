require "sidekiq"
require "sidekiq-activerecord"

RSpec.configure do |config|
  config.alias_example_to :expect_it

  config.expect_with :rspec do |config|
    config.syntax = :expect
  end
end
