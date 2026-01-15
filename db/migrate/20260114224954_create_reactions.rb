class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :reactions do |t|
      t.references :status_update, null: false, foreign_key: true
      t.string :emoji
      t.string :user_identifier

      t.timestamps
    end
  end
end
