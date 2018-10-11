class AddAddressToTransaction < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :street_address, :text
    add_column :transactions, :street_address_2, :text
    add_column :transactions, :city, :text
    add_column :transactions, :state, :text
    add_column :transactions, :zip, :text
  end
end
