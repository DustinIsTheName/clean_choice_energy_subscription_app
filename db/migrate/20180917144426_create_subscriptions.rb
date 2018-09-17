class CreateSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :subscriptions do |t|

      t.string :first_name
      t.string :last_name
      t.string :email
      t.text :address
      t.integer :cc_number
      t.string :expiration
      t.integer :external_id, :limit => 8
      t.integer :product, :limit => 8
      t.integer :payment_service

      t.timestamps
    end
  end
end
