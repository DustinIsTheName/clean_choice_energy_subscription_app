class CreateTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :transactions do |t|

      t.string :name
      t.string :email
      t.integer :product, :limit => 8
      t.integer :amount
      t.integer :cc_number
      t.boolean :status
      t.text :error_codes
      t.integer :import_id

      t.timestamps
    end
  end
end
