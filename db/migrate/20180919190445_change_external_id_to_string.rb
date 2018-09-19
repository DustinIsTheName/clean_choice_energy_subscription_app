class ChangeExternalIdToString < ActiveRecord::Migration[5.0]
  def change

    change_column :subscriptions, :external_id, :string

  end
end
