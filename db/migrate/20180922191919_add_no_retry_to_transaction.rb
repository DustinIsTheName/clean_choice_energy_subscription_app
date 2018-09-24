class AddNoRetryToTransaction < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :no_retry, :boolean
  end
end
