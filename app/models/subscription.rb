class Subscription < ApplicationRecord
  serialize :address, Hash

  validates :first_name, :last_name, :address, :cc_number, presence: true

  self.per_page = 25
end
