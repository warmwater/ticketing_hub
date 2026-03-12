class AddSeatingFields < ActiveRecord::Migration[8.1]
  def change
    # Event: seat selection mode
    add_column :events, :seat_selection_mode, :integer, null: false, default: 0

    # TicketType: link to venue section
    add_reference :ticket_types, :section, null: true, foreign_key: true

    # Ticket: seat assignment + denormalized display fields
    add_reference :tickets, :seat, null: true, foreign_key: true
    add_column :tickets, :section_name, :string
    add_column :tickets, :row_label, :string
    add_column :tickets, :seat_number, :integer
  end
end
