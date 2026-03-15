class CreateSeatHolds < ActiveRecord::Migration[8.1]
  def change
    create_table :seat_holds do |t|
      t.references :seat,  null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.datetime   :expires_at, null: false
      t.timestamps
    end

    # A seat can only have one active hold per event at a time.
    # Enforced at DB level via unique index — application layer expires old holds
    # before inserting a new one, so this prevents true race-condition duplicates.
    add_index :seat_holds, [ :seat_id, :event_id ], unique: true,
              name: "index_seat_holds_on_seat_and_event"
    add_index :seat_holds, :expires_at,
              name: "index_seat_holds_on_expires_at"
    add_index :seat_holds, [ :user_id, :event_id ],
              name: "index_seat_holds_on_user_and_event"
  end
end
