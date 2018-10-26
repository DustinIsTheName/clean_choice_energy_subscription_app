class AddStripeCustomerIdToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :stripe_customer_id, :string
  end
end
