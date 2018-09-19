class RemoveExternalIdLimit < ActiveRecord::Migration[5.0]
  def change
    change_column :subscriptions, :external_id, :string, :limit => nil
  end
end
