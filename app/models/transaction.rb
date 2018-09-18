class Transaction < ApplicationRecord

  belongs_to :import

  serialize :error_codes, Array

end
