# Sidekiq::Activerecord

Encapsulates various interactions between Sidekiq and ActiveRecord.

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-activerecord'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-activerecord

# Usage

If you've been using Sidekiq for a while, you've probably noticed a recurring pattern in your workers;

## Child-Parent Workers
A parent worker which goes over some model collection and enqueues a child worker for each model in the collection.

```ruby
class ParentWorker
  include Sidekiq::Worker

  def perform
    User.active.each do |user|
      ChildWorker.perform_async(user.id)
    end
  end

end
```

## Sidekiq::ManagerWorker - Example

```ruby
class UserTaskWorker
  include Sidekiq::TaskWorker
end

class UserSyncer
  include Sidekiq::ManagerWorker

  sidekiq_delegate_task_to :user_task_worker # or UserTaskWorker
  sidekiq_manager_options :batch_size => 500,
                          :identifier_key => :user_token,
                          :additional_keys => [:status]
end

UserSyncer.perform_query_async(User.active, :batch_size => 300)
```

## Model Task Workers

A worker which gets a model.id (like ChildWorker above) loads it, validates it and runs some logic on the model.

```ruby
class ModelTaskWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    return unless user.present?
    return unless user.active?

    UserService.run(user)
  end

end
```

## Sidekiq::TaskWorker - Example

```ruby
class UserMailerTaskWorker
  include Sidekiq::TaskWorker

  sidekiq_task_model :user_model # or UserModel
  sidekiq_task_options :identifier_key => :token

  def perform_on_model(user, email_type)
    UserMailer.deliver_registration_confirmation(user, email_type)
  end

  # optional
  def not_found_model(token)
    Log.error "User not found for token:#{token}"
  end

  # optional
  def model_valid?(user)
    user.active?
  end

  # optional
  def invalid_model(user)
    Log.error "User #{user.token} is invalid"
  end

end


UserMailerTaskWorker.perform(user.id, :new_email)
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/sidekiq-activerecord/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
