class CreateSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :seats do |t|
      t.references :section, null: false, foreign_key: true
      t.string :row_label, null: false
      t.integer :seat_number, null: false
      t.string :label
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :seats, [:section_id, :row_label, :seat_number], unique: true, name: "idx_seats_unique_in_section"
  end
end
