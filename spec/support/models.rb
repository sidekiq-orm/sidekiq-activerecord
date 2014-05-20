class User < ActiveRecord::Base
  scope :active, -> { where(:status => :active) }
  scope :banned, -> { where(:status => :banned) }
end