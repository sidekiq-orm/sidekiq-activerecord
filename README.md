[Sidekiq::Activerecord](https://github.com/sidekiq-orm/sidekiq-activerecord) encapsulates common patterns and various interactions between [Sidekiq](https://github.com/mperham/sidekiq) and [ActiveRecord](http://guides.rubyonrails.org/active_record_basics.html).

[![Build Status](https://travis-ci.org/sidekiq-orm/sidekiq-activerecord.svg?branch=master)](https://travis-ci.org/sidekiq-orm/sidekiq-activerecord)

***

## Common Patterns
If you've been using Sidekiq for a while, you've probably noticed a recurring pattern in your workers:


## [Sidekiq::ActiveRecord::TaskWorker](https://github.com/sidekiq-orm/sidekiq-activerecord/wiki/Task-Worker)
A very conventional pattern, is to have a worker that gets a model identifier, loads it and runs some custom logic on the model. 

[```TaskWorker```](https://github.com/sidekiq-orm/sidekiq-activerecord/wiki/Task-Worker) provides a simple and clean interface, which reduces the boilerplate and exposes only the custom logic.   

Here's a simple example:

```ruby
class UserTaskWorker < Sidekiq::ActiveRecord::TaskWorker

  sidekiq_task_model :user # or User

  def perform_on_user
    UserService.run(user)
  end
  
end
```
For a more see the [TaskWorker documention](https://github.com/sidekiq-orm/sidekiq-activerecord/wiki/Task-Worker).


***


## [Sidekiq::ActiveRecord::ManagerWorker](https://github.com/sidekiq-orm/sidekiq-activerecord/wiki/Manager-Worker)
Another farily common ```Sidekiq::Worker``` pattern, is a parent worker which goes over a model collection and enqueues a child worker for each model in the collection.

Here's a simple example:
```ruby
# Parent Worker
class UserSyncer < Sidekiq::ActiveRecord::ManagerWorker
  sidekiq_delegate_task_to :user_task_worker # or UserTaskWorker
end
```
Then, just call the worker with the model collection:
```ruby
UserSyncer.perform_query_async(User.active)
```

For a more see the [ManagerWorker documention](https://github.com/sidekiq-orm/sidekiq-activerecord/wiki/Manager-Worker).

***

# Documention
Checkout the project's [Wiki Page](https://github.com/sidekiq-orm/sidekiq-activerecord/wiki)

***

# Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-activerecord'

And then execute:

    $ bundle
    
***

## Contributing

1. Fork it ( http://github.com/sidekiq-orm/sidekiq-activerecord/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
