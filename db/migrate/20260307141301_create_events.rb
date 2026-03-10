class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.references :venue, null: false, foreign_key: true
      t.references :organizer, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.boolean :waiting_room_enabled, default: false
      t.integer :waiting_room_capacity, default: 50
      t.integer :waiting_room_admission_minutes, default: 10
      t.integer :max_tickets_per_order, default: 10
      t.string :cover_image_url

      t.timestamps
    end

    add_index :events, :status
    add_index :events, :starts_at
  end
end
