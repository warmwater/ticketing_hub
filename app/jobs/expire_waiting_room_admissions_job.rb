class ExpireWaitingRoomAdmissionsJob < ApplicationJob
  queue_as :default

  # Periodically checks for expired admissions and triggers queue processing.
  # Runs every minute via recurring schedule.
  def perform
    Event.published.where(waiting_room_enabled: true).find_each do |event|
      expired_count = event.waiting_room_entries.admitted
                          .where("expires_at < ?", Time.current)
                          .count

      if expired_count > 0
        AdmitNextUserJob.perform_later(event.id)
      end
    end
  end
end
