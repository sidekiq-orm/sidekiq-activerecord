RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods # Don't need to write FactoryGirl.create => create
end

FactoryGirl.define do
  factory :user do

    sequence(:first_name) { |n| "first-name-#{n}" }
    sequence(:last_name) { |n| "last-name-#{n}" }
    sequence(:email) { |n| "email-#{n}" }

    trait :active do
      status 'active'
    end

    trait :banned do
      status 'banned'
    end

  end
end
