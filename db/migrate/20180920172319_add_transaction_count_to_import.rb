class AddTransactionCountToImport < ActiveRecord::Migration[5.0]
  def change
    add_column :imports, :transaction_count, :integer
  end
end
