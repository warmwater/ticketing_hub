class Seat < ApplicationRecord
  belongs_to :section
  has_one :venue, through: :section

  validates :row_label, presence: true
  validates :seat_number, presence: true,
            numericality: { greater_than: 0 },
            uniqueness: { scope: [:section_id, :row_label] }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:row_label, :seat_number) }

  def display_label
    label.presence || "#{row_label}#{seat_number}"
  end

  def taken_for_event?(event)
    Ticket.joins(order_item: :ticket_type)
          .where(ticket_types: { event_id: event.id })
          .where(seat_id: id)
          .where.not(status: :cancelled)
          .exists?
  end
end
