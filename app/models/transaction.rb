class Transaction < ApplicationRecord

  belongs_to :import

  serialize :address, Hash
  serialize :error_codes, Array

end
