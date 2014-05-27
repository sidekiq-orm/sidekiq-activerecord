module Sidekiq
  module ActiveRecord
    module TaskWorker

      def self.included(base)
        base.extend(Sidekiq::Worker::ClassMethods)
        base.extend(ClassMethods)
        base.class_attribute :sidekiq_options_hash
        base.class_attribute :sidekiq_task_options_hash
      end

      module ClassMethods
        # @example:
        #   class UserMailerTaskWorker
        #     include Sidekiq::ActiveRecord::TaskWorker
        #
        #     sidekiq_task_model :user_model # or UserModel
        #     sidekiq_task_options :identifier_key => :token
        #
        #     def perform_on_model(user, email_type)
        #       UserMailer.deliver_registration_confirmation(user, email_type)
        #     end
        #
        #     def not_found_model(token)
        #       Log.error "User not found for token:#{token}"
        #     end
        #
        #     def model_valid?(user)
        #       user.active?
        #     end
        #
        #     def invalid_model(user)
        #       Log.error "User #{user.token} is invalid"
        #     end
        #
        #   end
        #
        #
        #   UserMailerTaskWorker.perform(user.id, :new_email)
        #
        def perform_async(identifier, *args)
          model = fetch_model(identifier)
          return not_found_model(identifier) unless model.present?

          if model_valid?(model)
            perform_on_model(model, *args)
          else
            invalid_model(model)
          end
        end

        def sidekiq_task_model(model_klass)
          if model_klass.is_a?(String) || model_klass.is_a?(Symbol)
            model_klass = model_klass.to_s.split('_').map(&:capitalize).join.constantize
          else
            model_klass
          end
          get_sidekiq_task_options[:model_class] = model_klass
        end

        def perform_on_model(model)
          model
        end

        # recheck the if one of the items is still valid
        def model_valid?(_model)
          true
        end

        # Hook to handel an invalid model
        def invalid_model(_model)
        end

        # Hook to handel not found model
        def not_found_model(_identifier)
        end

        # private

        def fetch_model(identifier)
          model_class.find_by(identifier_key => identifier)
        end

        def model_class
          klass = get_sidekiq_task_options[:model_class]
          fail NotImplementedError.new('`model_class` was not specified') unless klass.present?
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
          self.sidekiq_task_options_hash = get_sidekiq_task_options.merge((opts || {}).symbolize_keys!)
        end

        def get_sidekiq_task_options
          self.sidekiq_task_options_hash ||= default_worker_task_options
        end

        def default_worker_task_options
          {
              identifier_key: :id
          }
        end
      end
    end
  end
end
