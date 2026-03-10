class AdmitNextUserJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event&.waiting_room_active?

    # Ensure event config is in Redis for middleware
    Event.cache_waiting_room_config(event)

    # Expire any expired admissions
    event.waiting_room_entries.admitted.where("expires_at < ?", Time.current).find_each do |entry|
      entry.update!(status: :expired)
      # after_commit callback cleans up Redis token
    end

    # Count currently admitted users
    currently_admitted = event.waiting_room_entries.admitted.where("expires_at >= ?", Time.current).count

    # Calculate available spots
    spots_available = event.waiting_room_capacity - currently_admitted
    return if spots_available <= 0

    # Admit next users in queue
    next_in_line = event.waiting_room_entries.active_queue.limit(spots_available)

    next_in_line.each do |entry|
      entry.admit!
      # after_commit callback writes token and status to Redis

      # Broadcast admission via Turbo Stream
      Turbo::StreamsChannel.broadcast_replace_to(
        "waiting_room_entry_#{entry.id}",
        target: "waiting_room_status",
        partial: "waiting_rooms/admitted",
        locals: { entry: entry, event: event }
      )
    end

    # Broadcast position updates to remaining waiting users
    # and refresh their cached status in Redis
    remaining = event.waiting_room_entries.active_queue
    total_waiting = remaining.count

    remaining.each_with_index do |entry, index|
      position = index + 1

      # Explicitly refresh Redis cache with new position
      entry.cache_entry_status

      Turbo::StreamsChannel.broadcast_replace_to(
        "waiting_room_entry_#{entry.id}",
        target: "waiting_room_status",
        partial: "waiting_rooms/position",
        locals: { entry: entry, position: position, total: total_waiting }
      )
    end
  end
end
