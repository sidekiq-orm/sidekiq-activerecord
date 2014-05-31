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
      #     def model_valid?
      #       user.active?
      #     end
      #
      #     def invalid_model
      #       Log.error "User #{user.token} is invalid"
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

        if model_valid?
          perform_on_model(*args)
        else
          invalid_model
        end
      end

      def perform_on_model(*args)
        task_model
      end

      # recheck the if one of the items is still valid
      def model_valid?
        true
      end

      # Hook to handel an invalid model
      def invalid_model
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
          model_klass = model_class_name_to_const(model_klass)
          validate_model_class(model_klass)

          get_sidekiq_task_options[:model_class] = model_klass
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
          @sidekiq_task_options_hash = get_sidekiq_task_options.merge((opts || {}).symbolize_keys!)
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
        #   def admin_user_valid?; end
        #   def invalid_admin_user; end
        #
        def setup_task_model_alias(model_klass_name)
          if model_klass_name.is_a?(Class)
            model_klass_name = model_klass_name.name.underscore
          end
          {
              :task_model =>       model_klass_name,
              :fetch_model =>      "fetch_#{model_klass_name}",
              :not_found_model =>  "not_found_#{model_klass_name}",
              :model_valid? =>     "#{model_klass_name}_valid?",
              :invalid_model =>    "invalid_#{model_klass_name}",
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

        def model_class_name_to_const(model_klass)
          if model_klass.is_a?(String) || model_klass.is_a?(Symbol)
            begin
              model_klass = model_klass.to_s.split('_').map(&:capitalize).join.constantize
            rescue NameError
              fail ArgumentError.new'`sidekiq_task_model` must be a class' unless model_klass.is_a?(Class)
            end
          end
          model_klass
        end

        def validate_model_class(model_klass)
          unless model_klass.ancestors.include?(::ActiveRecord::Base)
            fail ArgumentError.new'`sidekiq_task_model` must be an ActiveRecord model'
          end
        end

      end

    end
  end
end
