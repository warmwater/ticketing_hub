# frozen_string_literal: true

# Mixed into Event model to sync waiting room configuration to Redis.
# The middleware reads this config to decide whether to intercept requests.
module WaitingRoomCacheable
  extend ActiveSupport::Concern

  class_methods do
    # Write event's waiting room config to Redis so the middleware can read it
    # without touching ActiveRecord.
    def cache_waiting_room_config(event)
      WaitingRoomRedis.set(
        "event:#{event.id}:config",
        {
          enabled: event.waiting_room_active?,
          capacity: event.waiting_room_capacity,
          admission_minutes: event.waiting_room_admission_minutes,
          event_name: event.name
        },
        ex: 5.minutes.to_i
      )
    end

    def invalidate_waiting_room_config(event_id)
      WaitingRoomRedis.del("event:#{event_id}:config")
    end
  end

  included do
    after_commit :sync_waiting_room_config_to_redis, if: :waiting_room_config_changed?
  end

  private

  def waiting_room_config_changed?
    saved_change_to_waiting_room_enabled? ||
      saved_change_to_waiting_room_capacity? ||
      saved_change_to_waiting_room_admission_minutes? ||
      saved_change_to_name? ||
      saved_change_to_status?
  end

  def sync_waiting_room_config_to_redis
    self.class.cache_waiting_room_config(self)
  end
end
