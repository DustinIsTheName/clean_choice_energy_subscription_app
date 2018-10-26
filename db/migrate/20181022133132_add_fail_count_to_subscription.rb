class AddFailCountToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :fail_count, :integer
  end
end
