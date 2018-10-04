class AddSubscriptionIdToTransaction < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :subscription_id, :integer
  end
end
