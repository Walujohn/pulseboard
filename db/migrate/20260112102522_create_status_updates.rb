class CreateStatusUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :status_updates do |t|
      t.text :body
      t.string :mood
      t.integer :likes_count, null: false, default: 0

      t.timestamps
    end
  end
end
