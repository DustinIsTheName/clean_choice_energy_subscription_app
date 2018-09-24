class ChangePaymentServiceToString < ActiveRecord::Migration[5.0]
  def change
    change_column :subscriptions, :payment_service, :string
  end
end
