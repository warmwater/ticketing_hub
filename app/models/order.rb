class Order < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :order_items, dependent: :destroy
  has_many :tickets, through: :order_items

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }

  validates :reference_number, presence: true, uniqueness: true

  before_validation :generate_reference_number, on: :create

  accepts_nested_attributes_for :order_items, reject_if: proc { |attrs| attrs["quantity"].to_i <= 0 }

  def calculate_total
    self.total_amount = order_items.sum { |item| item.quantity * item.unit_price }
  end

  def generate_tickets!(seat_assignments = {})
    ActiveRecord::Base.transaction do
      order_items.each do |item|
        section = item.ticket_type.section
        seats_for_item = seat_assignments[item.ticket_type_id.to_s] || []

        item.quantity.times do |i|
          seat = seats_for_item[i]

          attrs = {
            barcode: SecureRandom.hex(16).upcase,
            status: :active,
            attendee_name: user.name,
            attendee_email: user.email
          }

          if seat.present?
            # Pessimistic lock: prevents two concurrent transactions from
            # assigning the same seat between our check and the INSERT.
            seat = Seat.lock.find(seat.id)

            if seat.taken_for_event?(event)
              raise ActiveRecord::Rollback,
                    "Seat #{seat.display_label} was just taken by someone else"
            end

            attrs.merge!(
              seat: seat,
              section_name: section&.name,
              row_label: seat.row_label,
              seat_number: seat.seat_number
            )
          elsif section.present?
            attrs[:section_name] = section.name
          end

          item.tickets.create!(attrs)
        end
      end
    end
  end

  def broadcast_taken_seats
    seated_tickets = tickets.includes(:seat).where.not(seat_id: nil)
    return if seated_tickets.empty?

    seated_tickets.each do |ticket|
      Turbo::StreamsChannel.broadcast_replace_to(
        "event_#{event_id}_seats",
        target: "seat_#{ticket.seat_id}",
        partial: "orders/taken_seat",
        locals: { seat: ticket.seat }
      )
    end
  end

  private

  def generate_reference_number
    self.reference_number ||= "ORD-#{SecureRandom.alphanumeric(8).upcase}"
  end
end
