class CreateTicketTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_types do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0.0
      t.integer :quantity, null: false
      t.integer :max_per_order, default: 10
      t.datetime :sale_starts_at
      t.datetime :sale_ends_at

      t.timestamps
    end
  end
end
