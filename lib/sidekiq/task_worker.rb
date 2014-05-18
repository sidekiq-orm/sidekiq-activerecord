require 'sidekiq/client'
require 'sidekiq/worker'

module Sidekiq
  module TaskWorker
    include Sidekiq::Worker

    module ClassMethods

      # @example:
      #   class UserMailerTaskWorker
      #     include Sidekiq::TaskWorker
      #
      #     sidekiq_task_options :identifier_key => :token,
      #                          :model_class => :user
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
      def perform(identifier, *args)
        model = fetch_model(identifier)
        return not_found_model(identifier) unless model.present?

        if model_valid?(model)
          perform_on_model(model, *args)
        else
          invalid_model(model)
        end
      end

      def perform_on_model(model)
        model
      end

      # recheck the if one of the items is still valid
      def model_valid?(model)
        true
      end

      # Hook to handel an invalid model
      def invalid_model(model)
      end

      # Hook to handel not found model
      def not_found_model(identifier)
      end

      
      private

      def fetch_model(identifier)
        model_class.find_by(identifier_key => identifier)
      end

      def model_class
        klass = self.get_sidekiq_task_options[:model_class]
        raise NotImplementedError.new('`model_class` was not specified') unless klass.present?
        if klass.is_a?(String) or is_a?(Symbol)
          klass.to_s.split('_').collect(&:capitalize).join.constantize
        else
          klass
        end
      end

      def identifier_key
        self.get_sidekiq_task_options[:identifier_key]
      end

      #
      # Allows customization for this type of TaskWorker.
      # Legal options:
      #
      #   :model_class - the task's model class. (Required)
      #   :identifier_key - the model identifier column. Default 'id'
      def sidekiq_task_options(opts={})
        self.sidekiq_task_options_hash = get_sidekiq_task_options.merge((opts || {}).stringify_keys)
      end

      def get_sidekiq_task_options
        self.sidekiq_task_options_hash ||= default_worker_task_options
      end

      def default_worker_task_options
        {
            :identifier_key => :id,
            :model_class => nil
        }
      end

    end

  end
end