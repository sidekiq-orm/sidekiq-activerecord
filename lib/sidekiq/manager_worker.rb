require 'sidekiq/client'
require 'sidekiq/worker'

module Sidekiq
  module ManagerWorker
    include Sidekiq::Worker

    module ClassMethods

      # For a given model collection, it delegates each model to a sub-worker (e.g TaskWorker)
      #
      # @param models_query ActiveRecord::Relation
      # @param options Hash
      #   :worker_class - the worker class to delegate the task to. (Required)
      #   :identifier_key - the model identifier column. Default 'id'
      #   :additional_keys - additional model keys
      #   :batch_size - Specifies the size of the batch. Default to 1000.
      #
      # @example:
      #   class UserTaskWorker
      #     include Sidekiq::TaskWorker
      #   end
      #
      #   class UserSyncer
      #     include Sidekiq::ManagerWorker
      #
      #     sidekiq_manager_options :batch_size => 500,
      #                             :worker_class => :user_task_worker,
      #                             :identifier_key => :user_token,
      #                             :additional_keys => [:status]
      #   end
      #
      #   UserSyncer.perform_query_async(User.active, :batch_size => 300)
      #
      #
      # is equivalent to doing:
      #   User.active.each {|user| UserTaskWorker.peform(user.id) }
      #
      def perform_query_async(models_query, options)
        batch_size = options[:batch_size] || get_sidekiq_manager_options
        models = models_query.select(selected_attributes)
        models.find_in_batches(batch_size: batch_size) do |models_batch|
          model_attributes = models_batch.map { |model| model_attributes(model) }
          Sidekiq::Client.push_bulk('class' => worker_class, 'args' => model_attributes)
        end
      end

      #
      # Allows customization for this type of ManagerWorker.
      # Legal options:
      #
      #   :worker_class - the worker class to delegate the task to. (Required)
      #   :identifier_key - the model identifier column. Default 'id'
      #   :additional_keys - additional model keys
      #   :batch_size - Specifies the size of the batch. Default to 1000.
      def sidekiq_manager_options(opts={})
        self.sidekiq_manager_options_hash = get_sidekiq_manager_options.merge((opts || {}).stringify_keys)
      end


      private

      def default_worker_manager_options
        {
            :identifier_key => :id,
            :additional_keys => [],
            :worker_class => nil,
            :batch_size => 1000,
        }
      end

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

      def worker_class
        klass = self.get_sidekiq_manager_options[:worker_class]
        raise NotImplementedError.new('`worker_class` was not specified') unless klass.present?
        if klass.is_a?(String) or is_a?(Symbol)
          klass.to_s.split('_').collect(&:capitalize).join.constantize
        else
          klass
        end
      end

      def identifier_key
        self.get_sidekiq_manager_options[:identifier_key]
      end

      def additional_keys
        self.get_sidekiq_manager_options[:additional_keys]
      end

      def get_sidekiq_manager_options
        self.sidekiq_manager_options_hash ||= default_worker_manager_options
      end

    end
  end
end
