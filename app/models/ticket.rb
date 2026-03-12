class Ticket < ApplicationRecord
  belongs_to :order_item
  belongs_to :seat, optional: true
  has_one :ticket_type, through: :order_item
  has_one :order, through: :order_item
  has_one :event, through: :ticket_type

  enum :status, { pending: 0, active: 1, used: 2, cancelled: 3 }

  validates :barcode, presence: true, uniqueness: true
  validate :seat_not_double_booked, if: -> { seat_id.present? && seat_id_changed? }

  before_validation :generate_barcode, on: :create

  scope :valid_tickets, -> { where(status: [:active]) }

  def seat_label
    if seat.present?
      "#{section_name} — Row #{row_label}, Seat #{read_attribute(:seat_number)}"
    elsif section_name.present?
      "#{section_name} (General Admission)"
    end
  end

  private

  def generate_barcode
    self.barcode ||= SecureRandom.hex(16).upcase
  end

  def seat_not_double_booked
    conflicting = Ticket.joins(order_item: :ticket_type)
                        .where(seat_id: seat_id)
                        .where(ticket_types: { event_id: ticket_type&.event_id })
                        .where.not(status: :cancelled)
                        .where.not(id: id)
    errors.add(:seat, "is already taken for this event") if conflicting.exists?
  end
end
