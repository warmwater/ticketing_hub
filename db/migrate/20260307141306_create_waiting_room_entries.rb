class CreateWaitingRoomEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :waiting_room_entries do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.string :admission_token
      t.datetime :admitted_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :waiting_room_entries, [:event_id, :user_id], unique: true
    add_index :waiting_room_entries, :admission_token, unique: true
    add_index :waiting_room_entries, :status
  end
end
