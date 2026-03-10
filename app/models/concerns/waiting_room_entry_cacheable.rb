# frozen_string_literal: true

# Mixed into WaitingRoomEntry model to sync entry status and admission tokens
# to Redis. The middleware reads these to check queue position and validate
# admission without touching ActiveRecord.
module WaitingRoomEntryCacheable
  extend ActiveSupport::Concern

  included do
    after_commit :sync_waiting_room_entry_to_redis
  end

  # Write current entry status to Redis (position, total, status)
  def cache_entry_status
    ttl = if waiting?
            30 # Refresh frequently for waiting users
          elsif admitted? && expires_at
            [(expires_at - Time.current).to_i, 60].max
          else
            300 # 5 min default for completed/expired/left
          end

    WaitingRoomRedis.set(
      "entry:#{id}:status",
      {
        status: status,
        position: waiting? ? queue_position : nil,
        total: total_waiting,
        admission_token: admission_token,
        expires_at: expires_at&.iso8601
      },
      ex: ttl
    )
  end

  # Write admission token to Redis for fast middleware validation
  def cache_admission_token
    return unless admission_token.present? && expires_at.present?

    ttl = [(expires_at - Time.current).to_i, 60].max

    WaitingRoomRedis.set(
      "token:#{admission_token}",
      {
        event_id: event_id,
        entry_id: id,
        expires_at: expires_at.iso8601
      },
      ex: ttl
    )
  end

  # Remove admission token from Redis when expired/completed/left
  def remove_cached_admission_token
    WaitingRoomRedis.del("token:#{admission_token}") if admission_token.present?
  end

  # Remove entry status from Redis
  def remove_cached_entry_status
    WaitingRoomRedis.del("entry:#{id}:status")
  end

  private

  def sync_waiting_room_entry_to_redis
    cache_entry_status

    if admitted? && admission_token.present?
      cache_admission_token
    elsif status_previously_changed? && (expired? || left? || completed?)
      remove_cached_admission_token
    end
  end
end
