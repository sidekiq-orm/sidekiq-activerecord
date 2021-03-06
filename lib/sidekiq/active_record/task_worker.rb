module Sidekiq
  module ActiveRecord
    class TaskWorker
      include Sidekiq::Worker

      attr_reader :task_model

      # Helper method, to automatically call the task worker with the identifier.
      # This will allow you to change the :identifier_key option, without needing to change it in other places.
      #
      # @example:
      #   class UserMailerTaskWorker < Sidekiq::ActiveRecord::TaskWorker
      #
      #     sidekiq_task_model User
      #     sidekiq_task_options :identifier_key => :email
      #
      #   end
      #
      #   user = User.find_by(:email => user@mail.com)
      #
      #   UserMailerTaskWorker.perform_async(user.email, arg1, arg2)
      #
      #   # is the same as doing
      #   UserMailerTaskWorker.perform_async_on(user, arg1, arg2)
      #
      def self.perform_async_on(model, *args)
        fail ArgumentError.new "Specified model must be a #{model_class.to_s}" unless model.class <= model_class
        identifier = model.send(self.identifier_key)
        perform_async(identifier, *args)
      end

      # @example:
      #   class UserMailerTaskWorker < Sidekiq::ActiveRecord::TaskWorker
      #
      #     sidekiq_task_model :user_model # or UserModel
      #     sidekiq_task_options :identifier_key => :token
      #
      #     def perform_on_model
      #       UserMailer.deliver_registration_confirmation(user, email_type)
      #     end
      #
      #     def not_found_model(token)
      #       Log.error "User not found for token:#{token}"
      #     end
      #
      #     def should_perform_on_model?
      #       user.active?
      #     end
      #
      #     def did_not_perform_on_model
      #       Log.error "User #{user.token} is inactive"
      #     end
      #
      #   end
      #
      #
      #   UserMailerTaskWorker.perform_async(user.id, :new_email)
      #
      def perform(identifier, *args)
        @task_model = call_alias_method(:fetch_model, identifier, *args)
        return call_alias_method(:not_found_model, identifier, *args) unless @task_model.present?

        if call_alias_method(:should_perform_on_model?)
          call_alias_method(:perform_on_model, *args)
        else
          call_alias_method(:did_not_perform_on_model)
        end
      end

      def perform_on_model(*args)
        task_model
      end

      # Hook that can block perform_on_model from being triggered,
      # e.g in cases when the model is no longer valid
      def should_perform_on_model?
        true
      end

      # Hook to handel a model that was not performed
      def did_not_perform_on_model
        task_model
      end

      # Hook to handel not found model
      def not_found_model(identifier, *args)
        identifier
      end

      def fetch_model(identifier, *args)
        self.class.model_class.find_by(self.class.identifier_key => identifier)
      end

      # Try calling the alias method, and fallback to default name if not defined
      def call_alias_method(method_name, *args)
        alias_name = self.class.method_aliases_mapping[method_name]
        if respond_to?(alias_name.to_sym)
          send(alias_name, *args)
        else
          send(method_name, *args)
        end
      end

      class << self

        def sidekiq_task_model(model_klass)
          return if model_klass.blank?

          setup_task_model_alias(model_klass)

          get_sidekiq_task_options[:model_class] = active_record_class(model_klass)
        end

        def model_class
          klass = get_sidekiq_task_options[:model_class]
          fail NotImplementedError.new('`sidekiq_task_model` was not specified') unless klass.present?
          klass
        end

        def identifier_key
          get_sidekiq_task_options[:identifier_key]
        end

        #
        # Allows customization for this type of TaskWorker.
        # Legal options:
        #
        #   :identifier_key - the model identifier column. Default 'id'
        def sidekiq_task_options(opts = {})
          @sidekiq_task_options_hash = get_sidekiq_task_options.merge((opts).symbolize_keys!)
        end

        def method_aliases_mapping
          @_method_aliases_mapping
        end

        private

        # aliases task_model with the name of the model
        #
        # example:
        #   sidekiq_task_model: AdminUser # or :admin_user
        #
        # then the worker will have access to `admin_user`, which is an alias to `task_model`
        #
        #   def perform_on_admin_user
        #     admin_user == task_model
        #   end
        #
        # it will add the following method aliases to the hooks:
        #
        #   def not_found_admin_user; end
        #   def should_perform_on_admin_user?; end
        #   def did_not_perform_on_admin_user; end
        #
        def setup_task_model_alias(model_klass_name)
          if model_klass_name.is_a?(Class)
            model_klass_name = model_klass_name.name.underscore
          end
          setup_method_aliases_mapping(model_klass_name)
          alias_method model_klass_name.to_sym, :task_model
        end

        def setup_method_aliases_mapping(model_klass_name)
          @_method_aliases_mapping = {
              :task_model => model_klass_name,
              :fetch_model => "fetch_#{model_klass_name}",
              :not_found_model => "not_found_#{model_klass_name}",
              :should_perform_on_model? => "should_perform_on_#{model_klass_name}?",
              :did_not_perform_on_model => "did_not_perform_on_#{model_klass_name}",
              :perform_on_model => "perform_on_#{model_klass_name}"
          }
        end

        def get_sidekiq_task_options
          @sidekiq_task_options_hash ||= default_worker_task_options
        end

        def default_worker_task_options
          {
              identifier_key: :id
          }
        end

        def active_record_class(model_klass)
          begin
            model_klass = model_klass.to_s.classify.constantize
            raise unless model_klass <= ::ActiveRecord::Base
          rescue
            fail ArgumentError.new '`sidekiq_task_model` must be an ActiveRecord model'
          end
          model_klass
        end

      end

    end
  end
end
