if RUBY_ENGINE == 'ruby' and RUBY_VERSION != '1.9.3'
  require 'byebug'
end
require 'sidekiq'
require 'sidekiq/testing/inline'
require 'sidekiq/activerecord'
require 'factory_girl'
require 'database_cleaner'

RSpec.configure do |config|
  config.alias_example_to :expect_it
end

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

