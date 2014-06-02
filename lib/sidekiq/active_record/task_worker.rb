module Sidekiq
  module ActiveRecord
    class TaskWorker
      include Sidekiq::Worker

      attr_reader :task_model

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
      #   UserMailerTaskWorker.perform(user.id, :new_email)
      #
      def perform(identifier, *args)
        @task_model = fetch_model(identifier)
        return not_found_model(identifier) unless @task_model.present?

        if should_perform_on_model?
          perform_on_model(*args)
        else
          did_not_perform_on_model
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
      def not_found_model(identifier)
        identifier
      end

      def fetch_model(identifier)
        self.class.model_class.find_by(self.class.identifier_key => identifier)
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
          {
              :task_model => model_klass_name,
              :fetch_model => "fetch_#{model_klass_name}",
              :not_found_model => "not_found_#{model_klass_name}",
              :should_perform_on_model? => "should_perform_on_#{model_klass_name}?",
              :did_not_perform_on_model => "did_not_perform_on_#{model_klass_name}",
              :perform_on_model => "perform_on_#{model_klass_name}"
          }.each do |old_name, new_name|
            self.class_exec do
              alias_method new_name.to_sym, old_name
            end
          end
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
