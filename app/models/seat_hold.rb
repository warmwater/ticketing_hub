class SeatHold < ApplicationRecord
  belongs_to :seat
  belongs_to :user
  belongs_to :event

  HOLD_DURATION = 10.minutes

  scope :active,  -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  validates :seat_id, uniqueness: { scope: :event_id,
    message: "is already held for this event" }

  def active?
    expires_at > Time.current
  end

  def expired?
    !active?
  end

  def seconds_remaining
    [ (expires_at - Time.current).to_i, 0 ].max
  end

  def minutes_remaining
    (seconds_remaining / 60.0).ceil
  end

  # Release all expired holds for an event and broadcast seats back to available.
  # Called at hold-creation time so expired holds never silently block seats.
  def self.release_expired_for_event!(event)
    expired.where(event: event).includes(seat: :section).find_each do |hold|
      hold.destroy
      broadcast_seat_available(hold.seat, event)
    end
  end

  def self.broadcast_seat_available(seat, event)
    ticket_type = TicketType.find_by(section: seat.section, event: event)
    return unless ticket_type

    Turbo::StreamsChannel.broadcast_replace_to(
      "event_#{event.id}_seats",
      target: "seat_#{seat.id}",
      partial: "orders/available_seat",
      locals: { seat: seat, ticket_type: ticket_type }
    )
  end
end
