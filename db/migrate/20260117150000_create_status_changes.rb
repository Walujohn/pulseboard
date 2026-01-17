class CreateStatusChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :status_changes do |t|
      t.references :status_update, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.text :reason, comment: "Why the status changed (optional)"
      t.timestamps
    end

    # Index for ordering: "Get most recent changes first"
    add_index :status_changes, [ :status_update_id, :created_at ]
  end
end
