module Sidekiq
  module ActiveRecord
    module ManagerWorker
      extend Sidekiq::Worker

      DEFAULT_IDENTIFIER_KEY = :id
      DEFAULT_BATCH_SIZE = 1000

      def self.included(base)
        base.extend(ClassMethods)
        base.class_attribute :sidekiq_manager_options_hash
      end

      module ClassMethods
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
        #   User.active.each {|user| UserTaskWorker.peform(user.id) }
        #
        def perform_query_async(models_query, options = {})
          set_runtime_options(options)
          models = models_query.select(selected_attributes)
          models.find_in_batches(batch_size: batch_size) do |models_batch|
            model_attributes = models_batch.map { |model| model_attributes(model) }
            Sidekiq::Client.push_bulk('class' => worker_class, 'args' => model_attributes)
          end
          # set_runtime_options(nil)
        end

        # @required
        # The task worker to delegate to.
        # @param worker_klass (Sidekiq::Worker, Symbol) - UserTaskWorker or :user_task_worker
        def sidekiq_delegate_task_to(worker_klass)
          if worker_klass.is_a?(String) or is_a?(Symbol)
            worker_klass.to_s.split('_').map(&:capitalize).join.constantize
          else
            worker_klass
          end
          get_sidekiq_manager_options[:worker_class] = worker_klass
        end

        # Allows customization for this type of ManagerWorker.
        # Legal options:
        #
        #   :worker_class - the worker class to delegate the task to. Alternative to `sidekiq_delegate_task_to`
        #   :identifier_key - the model identifier column. Default 'id'
        #   :additional_keys - additional model keys
        #   :batch_size - Specifies the size of the batch. Default to 1000.
        def sidekiq_manager_options(opts = {})
          self.sidekiq_manager_options_hash = get_sidekiq_manager_options.merge((opts || {}).symbolize_keys!)
        end

        # private

        def default_worker_manager_options
          {
              identifier_key: DEFAULT_IDENTIFIER_KEY,
              additional_keys: [],
              worker_class: nil,
              batch_size: DEFAULT_BATCH_SIZE
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
          attrs = [identifier_key, additional_keys]
          attrs << DEFAULT_IDENTIFIER_KEY unless default_identifier? # :id must be included
          attrs
        end

        def worker_class
          fail NotImplementedError.new('`worker_class` was not specified') unless manager_options[:worker_class].present?
          manager_options[:worker_class]
        end

        def default_identifier?
          identifier_key == DEFAULT_IDENTIFIER_KEY
        end

        def identifier_key
          manager_options[:identifier_key]
        end

        def additional_keys
          manager_options[:additional_keys]
        end

        def batch_size
          manager_options[:batch_size]
        end

        def manager_options
          get_sidekiq_manager_options.merge(runtime_options)
        end

        def get_sidekiq_manager_options
          self.sidekiq_manager_options_hash ||= default_worker_manager_options
        end

        def runtime_options
          @sidekiq_manager_runtime_options || {}
        end

        def set_runtime_options(options)
          options = options.delete_if { |k, v| v.nil? } if options.present?
          @sidekiq_manager_runtime_options = options
        end
      end
    end
  end
end
