module Sidekiq
  module ActiveRecord
    module TaskWorker
      extend Sidekiq::Orm::TaskWorker

      def self.included(base)
        base.extend(ClassMethods)
        base.class_attribute :sidekiq_task_options_hash
      end

      module ClassMethods
        include Sidekiq::Orm::TaskWorker::ClassMethods
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
        def fetch_model(identifier)
          model_class.find_by(identifier_key => identifier)
        end

      end
    end
  end
end
