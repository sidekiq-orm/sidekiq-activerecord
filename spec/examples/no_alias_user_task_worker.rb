module Examples
  class NoAliasUserTaskWorker < Sidekiq::ActiveRecord::TaskWorker

    sidekiq_task_model :user # or User class
    sidekiq_task_options :identifier_key => :email

    def perform_on_model(new_email = nil)
      UserMailer.update_email(task_model, new_email)
    end

    # optional
    def not_found_model(email)
      Log.error "User not found for email:#{email}"
    end

    # optional
    def should_perform_on_model?
      user.active?
    end

    # optional
    def did_not_perform_on_model
      Log.error "User #{task_model.id} is invalid"
    end

  end
end