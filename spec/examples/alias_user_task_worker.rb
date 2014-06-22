require 'examples/helper_classes'

module Examples
  class AliasUserTaskWorker < Sidekiq::ActiveRecord::TaskWorker

    sidekiq_task_model :user # or User class
    sidekiq_task_options :identifier_key => :email

    sidekiq_options :queue => USER_TASK_QUEUE

    def perform_on_user(new_email = nil)
      UserMailer.update_email(user, new_email)
    end

    # optional
    def not_found_user(email)
      Log.error "User not found for email:#{email}"
    end

    # optional
    def should_perform_on_user?
      user.active?
    end

    # optional
    def did_not_perform_on_user
      Log.error "User #{user.id} is invalid"
    end

  end
end