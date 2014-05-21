# dependencies
require 'sidekiq'
require 'active_record'

# core
require 'sidekiq/active_record/version'


module Sidekiq
  module ActiveRecord
    extend ActiveSupport::Autoload

    autoload :TaskWorker
    autoload :ManagerWorker
  end
end