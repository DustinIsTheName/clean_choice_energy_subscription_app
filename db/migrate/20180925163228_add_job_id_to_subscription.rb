class AddJobIdToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :job_id, :integer
  end
end
