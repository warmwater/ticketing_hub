class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.references :order_item, null: false, foreign_key: true
      t.string :barcode, null: false
      t.integer :status, null: false, default: 0
      t.string :attendee_name
      t.string :attendee_email

      t.timestamps
    end

    add_index :tickets, :barcode, unique: true
    add_index :tickets, :status
  end
end
