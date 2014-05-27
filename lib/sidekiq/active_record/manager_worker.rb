module Sidekiq
  module ActiveRecord
    module ManagerWorker
      extend Sidekiq::Orm::ManagerWorker

      def self.included(base)
        base.extend(ClassMethods)
        base.class_attribute :sidekiq_manager_options_hash
      end

      module ClassMethods
        include Sidekiq::Orm::ManagerWorker::ClassMethods
        # For a given model collection, it delegates each model to a sub-worker (e.g TaskWorker)
        # Specify the TaskWorker with the `sidekiq_delegate_task_to` method.
        #
        # @param models_query ActiveRecord::Relation
        # @param options Hash
        #   :worker_class - the worker class to delegate the task to. Alternative to the default `sidekiq_delegate_task_to`
        #   :identifier_key - the model identifier column. Default 'id'
        #   :additional_keys - additional model keys
        #   :batch_size - Specifies the size of the batch. Default to 1000.
        #
        # @example:
        #   class UserTaskWorker
        #     include Sidekiq::ActiveRecord::TaskWorker
        #   end
        #
        #   class UserSyncer
        #     include Sidekiq::ActiveRecord::ManagerWorker
        #
        #     sidekiq_delegate_task_to :user_task_worker # or UserTaskWorker
        #     sidekiq_manager_options :batch_size => 500,
        #                             :identifier_key => :user_token,
        #                             :additional_keys => [:status]
        #   end
        #
        #   UserSyncer.perform_query_async(User.active, :batch_size => 300)
        #
        #
        # is equivalent to doing:
        #   User.active.each {|user| UserTaskWorker.perform(user.id) }
        #

        def query_setup(models_query)
          models_query.select(selected_attributes)
        end

        def run_query(models_query)
          models_query.find_in_batches(batch_size: batch_size) do |models_batch|
            yield models_batch
          end
        end

      end
    end
  end
end
