class WaitingRoomEntry < ApplicationRecord
  include WaitingRoomEntryCacheable

  belongs_to :event
  belongs_to :user

  enum :status, { waiting: 0, admitted: 1, completed: 2, expired: 3, left: 4 }

  validates :user_id, uniqueness: { scope: :event_id, message: "already in waiting room" }

  scope :active_queue, -> { waiting.order(:created_at) }

  def queue_position
    event.waiting_room_entries.waiting.where("created_at <= ?", created_at).count
  end

  def total_waiting
    event.waiting_room_entries.waiting.count
  end

  def admit!
    update!(
      status: :admitted,
      admission_token: SecureRandom.urlsafe_base64(32),
      admitted_at: Time.current,
      expires_at: Time.current + event.waiting_room_admission_minutes.minutes
    )
  end

  def admission_expired?
    admitted? && expires_at.present? && expires_at < Time.current
  end

  def minutes_remaining
    return 0 unless admitted? && expires_at.present?
    [(expires_at - Time.current).to_i / 60, 0].max
  end
end
