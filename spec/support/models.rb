class User < ActiveRecord::Base
  scope :active, -> { where(:status => :active) }
  scope :banned, -> { where(:status => :banned) }

  def active?
    status.try(:to_sym) == :active
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end