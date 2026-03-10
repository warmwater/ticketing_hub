class WarmWaitingRoomCacheJob < ApplicationJob
  queue_as :default

  # Warms the Redis cache for all events with active waiting rooms.
  # Ensures the middleware has fresh data even after Redis flush or app restart.
  def perform
    Event.published.where(waiting_room_enabled: true).find_each do |event|
      # Cache event config
      Event.cache_waiting_room_config(event)

      # Cache admission tokens for currently admitted users
      event.waiting_room_entries.admitted.where("expires_at >= ?", Time.current).find_each do |entry|
        entry.cache_entry_status
        entry.cache_admission_token
      end

      # Cache status for waiting users
      event.waiting_room_entries.waiting.find_each do |entry|
        entry.cache_entry_status
      end
    end
  end
end
