require "active_record"

def set_database
  db_config = {:adapter => "sqlite3", :database => ":memory:"}
  ActiveRecord::Base.establish_connection(db_config)
  connection = ActiveRecord::Base.connection

  connection.create_table :users, force: true do |t|
    t.string :name
    t.string :email
    t.string :status
    t.timestamps
  end
end

set_database

class User < ActiveRecord::Base
  scope :active, -> { where(:status => :active) }
  scope :banned, -> { where(:status => :banned) }
end


FactoryGirl.define do
  factory :user do

    sequence(:name) { |n| "name-#{n}" }
    sequence(:email) { |n| "email-#{n}" }

    trait :active do
      status 'active'
    end

    trait :banned do
      status 'banned'
    end

  end
end
