class CreateSections < ActiveRecord::Migration[8.1]
  def change
    create_table :sections do |t|
      t.references :venue, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :section_type, null: false, default: 0
      t.integer :capacity, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :sections, [ :venue_id, :name ], unique: true
  end
end
