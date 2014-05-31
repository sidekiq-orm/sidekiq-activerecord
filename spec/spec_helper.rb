if RUBY_ENGINE == 'ruby'
  require 'byebug'
end
require 'sidekiq'
require 'sidekiq/activerecord'
require 'factory_girl'
require 'database_cleaner'

RSpec.configure do |config|
  config.alias_example_to :expect_it
end

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

