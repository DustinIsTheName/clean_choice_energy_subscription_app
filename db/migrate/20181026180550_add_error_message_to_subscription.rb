class AddErrorMessageToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :fail_message, :string
  end
end
