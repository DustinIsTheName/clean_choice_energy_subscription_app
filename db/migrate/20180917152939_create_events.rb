class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|

      t.string :name
      t.string :type
      t.text :event_lines

      t.timestamps
    end
  end
end
