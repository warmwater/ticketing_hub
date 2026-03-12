class Event < ApplicationRecord
  include WaitingRoomCacheable

  belongs_to :organizer, class_name: "User"
  belongs_to :venue
  has_many :ticket_types, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error
  has_many :waiting_room_entries, dependent: :destroy

  # File attachments
  has_one_attached :cover_image
  has_many_attached :media

  enum :status, { draft: 0, published: 1, cancelled: 2, completed: 3 }
  enum :seat_selection_mode, { none: 0, customer_pick: 1, auto_assign: 2 }, prefix: :seating

  validates :name, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_after_starts
  validate :acceptable_cover_image
  validate :acceptable_media

  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :published_events, -> { published.upcoming }

  ACCEPTABLE_IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  ACCEPTABLE_VIDEO_TYPES = %w[video/mp4 video/webm video/quicktime].freeze
  MAX_IMAGE_SIZE = 10.megabytes
  MAX_VIDEO_SIZE = 100.megabytes

  def total_capacity
    ticket_types.sum(:quantity)
  end

  def tickets_sold
    ticket_types.joins(:tickets).where(tickets: { status: [ :active, :used ] }).count
  end

  def tickets_available
    total_capacity - tickets_sold
  end

  def sold_out?
    tickets_available <= 0
  end

  def seated_event?
    !seating_none?
  end

  def waiting_room_active?
    waiting_room_enabled? && published?
  end

  def users_in_waiting_room
    waiting_room_entries.waiting.count
  end

  def video?(attachment)
    attachment.content_type.start_with?("video/")
  end

  def image?(attachment)
    attachment.content_type.start_with?("image/")
  end

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end

  def acceptable_cover_image
    return unless cover_image.attached?

    unless cover_image.content_type.in?(ACCEPTABLE_IMAGE_TYPES)
      errors.add(:cover_image, "must be a JPEG, PNG, GIF, or WebP image")
    end

    if cover_image.byte_size > MAX_IMAGE_SIZE
      errors.add(:cover_image, "is too large (maximum is 10MB)")
    end
  end

  def acceptable_media
    return unless media.attached?

    media.each do |file|
      acceptable_types = ACCEPTABLE_IMAGE_TYPES + ACCEPTABLE_VIDEO_TYPES
      unless file.content_type.in?(acceptable_types)
        errors.add(:media, "must be images (JPEG, PNG, GIF, WebP) or videos (MP4, WebM, MOV)")
        break
      end

      max_size = file.content_type.start_with?("video/") ? MAX_VIDEO_SIZE : MAX_IMAGE_SIZE
      if file.byte_size > max_size
        limit = file.content_type.start_with?("video/") ? "100MB" : "10MB"
        errors.add(:media, "files must be under #{limit}")
        break
      end
    end
  end
end
