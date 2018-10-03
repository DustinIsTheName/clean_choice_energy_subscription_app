class AddUserIdToImport < ActiveRecord::Migration[5.0]
  def change
    add_column :imports, :user_id, :integer
  end
end
