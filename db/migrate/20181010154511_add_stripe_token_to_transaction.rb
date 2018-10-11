class AddStripeTokenToTransaction < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :stripe_token, :string
  end
end
