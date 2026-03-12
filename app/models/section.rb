class Section < ApplicationRecord
  belongs_to :venue
  has_many :seats, dependent: :destroy
  has_many :ticket_types, dependent: :restrict_with_error

  enum :section_type, { general_admission: 0, seated: 1 }

  validates :name, presence: true, uniqueness: { scope: :venue_id }
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :name) }

  after_save :update_venue_capacity, if: :saved_change_to_capacity?
  after_destroy :update_venue_capacity

  def active_seats
    seats.where(active: true)
  end

  def available_seats_for_event(event)
    return Seat.none unless seated?

    sold_seat_ids = Ticket.joins(order_item: :ticket_type)
                         .where(ticket_types: { event_id: event.id })
                         .where.not(tickets: { status: :cancelled })
                         .where.not(seat_id: nil)
                         .pluck(:seat_id)

    active_seats.where.not(id: sold_seat_ids).order(:row_label, :seat_number)
  end

  def available_capacity_for_event(event)
    return 0 unless general_admission?

    sold_count = Ticket.joins(order_item: :ticket_type)
                       .where(ticket_types: { event_id: event.id, section_id: id })
                       .where.not(tickets: { status: :cancelled })
                       .count

    capacity - sold_count
  end

  def rows
    seats.where(active: true).order(:row_label, :seat_number).group_by(&:row_label)
  end

  private

  def update_venue_capacity
    venue.update_column(:capacity, venue.sections.sum(:capacity))
  end
end
