# Sidekiq::Activerecord

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-activerecord'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-activerecord

## Why it's good?

If you've been using Sidekiq for a while, you've probably noticed a recurring pattern in your workers;

### Child-Parent Workers (aka Sidekiq::ManagerWorker)
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

### Model Task Workers (aka Sidekiq::TaskWorker)

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

## Usage

## Contributing

1. Fork it ( http://github.com/<my-github-username>/sidekiq-activerecord/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
