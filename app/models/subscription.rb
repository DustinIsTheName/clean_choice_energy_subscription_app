class Subscription < ApplicationRecord
  serialize :address, Hash

  validates :first_name, :last_name, :address, :cc_number, presence: true
  validates_uniqueness_of :email, :allow_blank => true, :allow_nil => true
  validates_uniqueness_of :cc_number, :scope => [:first_name, :last_name]

  self.per_page = 25
end
