class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, default: 0.0
      t.string :reference_number, null: false

      t.timestamps
    end

    add_index :orders, :reference_number, unique: true
    add_index :orders, :status
  end
end
