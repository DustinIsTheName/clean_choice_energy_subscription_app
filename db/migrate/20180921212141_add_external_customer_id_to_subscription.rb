class AddExternalCustomerIdToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :external_customer_id, :string
  end
end
