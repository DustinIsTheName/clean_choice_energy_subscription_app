class AddAmountToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :amount, :integer
  end
end
