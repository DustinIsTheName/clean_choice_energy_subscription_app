class AddFullnameToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :full_name, :string
  end
end
