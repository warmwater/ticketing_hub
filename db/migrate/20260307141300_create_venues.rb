class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.text :address, null: false
      t.string :city
      t.string :state
      t.string :country
      t.integer :capacity
      t.text :description
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
