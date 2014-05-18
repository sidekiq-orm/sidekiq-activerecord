require 'sidekiq/client'
require 'sidekiq/worker'

module Sidekiq
  module Worker

    module ClassMethods

      def perform_async_query(models_query, options)
        models = models_query.select(selected_attributes)
        models.find_in_batches(batch_size: options[:batch_size]) do |models_batch|
          model_attributes = models_batch.map { |model| model_attributes(model) }
          Sidekiq::Client.push_bulk('class' => worker_class, 'args' => model_attributes)
        end
      end

      # The Sidekiq::Worker class to handel a single task
      # Needs to use Sidekiq::TaskWorker or simply accept
      #
      #   def perform(model_identifier, attr1, attr2, ...)
      #   end
      def worker_class
        raise NotImplementedError.new('`worker_class` was not defined')
      end

      def identifier_key
        :id
      end

      def additional_keys
        []
      end

      
      private

      # returns the model attributes array:
      # [model_id, attr1, attr2, ...]
      def model_attributes(model)
        additional_attributes = additional_keys.map { |key| model.send(key) }
        id_attribute = model.send(identifier_key)
        additional_attributes.unshift(id_attribute)
      end

      def selected_attributes
        identifier_key.merge(additional_keys)
      end

    end
  end
end