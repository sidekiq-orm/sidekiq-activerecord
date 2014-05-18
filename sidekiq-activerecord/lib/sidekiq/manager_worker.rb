require 'sidekiq/client'
require 'sidekiq/worker'

module Sidekiq
  module ManagerWorker

    include Sidekiq::Worker

    module ClassMethods

      def perform_async_query(models_query, options)
        models = models_query.select(:id)
        models.find_in_batches(batch_size: options[:batch_size]) do |models_batch|
          model_ids = models_batch.map {|model| [model.id]}
          Sidekiq::Client.push_bulk('class' => worker_class, 'args' => model_ids)
        end
      end

    end
  end
end