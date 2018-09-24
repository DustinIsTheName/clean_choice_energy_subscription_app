class ChangeCcNumberToString < ActiveRecord::Migration[5.0]
  def change
    change_column :subscriptions, :cc_number, :string
    change_column :transactions, :cc_number, :string
  end
end
