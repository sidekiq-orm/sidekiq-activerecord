module Sidekiq
  module Orm
    class ManagerWorker
      include Sidekiq::Worker

      DEFAULT_IDENTIFIER_KEY = :id
      DEFAULT_BATCH_SIZE = 1000

      def perform(options = {})
        default_query = self.class.get_default_models_query
        self.class.perform_query_async(default_query, options)
      end


      class << self

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
        #     def perform(user_id)
        #       # user task logic
        #     end
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
        def perform_query_async(models_query, options = {})
          set_runtime_options(options)
          models = prepare_models_query(models_query)
          find_in_batches(models) do |models_batch|
            model_attributes = models_batch.map { |model| model_attributes(model) }
            Sidekiq::Client.push_bulk(class: worker_class, args: model_attributes)
          end
        end

        # @required
        # The task worker to delegate to.
        # @param worker_klass (Sidekiq::Worker, Symbol) - UserTaskWorker or :user_task_worker
        def sidekiq_delegate_task_to(worker_klass)
          case worker_klass
          when String, Symbol
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
          @sidekiq_manager_options_hash = get_sidekiq_manager_options.merge((opts || {}))
        end

        # The default of query to run, when the workers runs perform
        # example
        #   class UserManagerWorker < Sidekiq::ActiveRecord::ManagerWorker
        #     sidekiq_delegate_task_to UserTaskWorker
        #     default_models_query -> { User.active }
        #   end
        #
        #   UserManagerWorker.perform_async(:batch_size => 300)
        def default_models_query(query)
          @query = query
        end

        def get_default_models_query
          @query.call() if @query.present?
        end

        def default_worker_manager_options
          {
              identifier_key: DEFAULT_IDENTIFIER_KEY,
              additional_keys: [],
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

        # @override in ORM specific class
        # Prepares the models collection, before it is executes.
        # For example, in the context of ActiveRecord - we won't to SELECT only the
        # needed columns we need. e.g:
        #
        # def prepare_models_query(models_query)
        #   selected_attributes = [models_query.primary_key.to_sym, identifier_key, additional_keys].uniq
        #   models_query.select(selected_attributes)
        # end
        #
        # Make sure you return the models query
        #
        # see: Sidekiq::ActiveRecord::ManagerWorker
        def prepare_models_query(models_query)
          models_query
        end

        # @override in ORM specific class
        # Goes over the models collection and yields each batch of records.
        # Essentially, a wrapper for ActiveRecord::Batches.find_in_batches
        # Example:
        #
        #   def find_in_batches(models)
        #     models.find_in_batches(batch_size: batch_size) do |batch|
        #       yield batch
        #     end
        #   end
        #
        # see: Sidekiq::ActiveRecord::ManagerWorker
        # see: http://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-find_in_batches
      end
        def find_in_batches(models)
        end

        def worker_class
          fail NotImplementedError.new('`worker_class` was not specified') unless manager_options[:worker_class].present?
          manager_options[:worker_class]
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
          @sidekiq_manager_options_hash ||= default_worker_manager_options
        end

        def runtime_options
          @sidekiq_manager_runtime_options || {}
        end

        def set_runtime_options(options={})
          @sidekiq_manager_runtime_options = options.delete_if { |_, v| v.to_s.strip == '' }
        end

      end

    end
  end
end
