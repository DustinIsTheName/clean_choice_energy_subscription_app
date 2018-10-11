class AddFirstAndLastNameToTransaction < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :first_name, :string
    add_column :transactions, :last_name, :string
  end
end
