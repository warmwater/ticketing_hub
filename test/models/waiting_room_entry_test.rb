require "test_helper"

class WaitingRoomEntryTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @event = events(:concert)
  end

  def build_entry(user: @alice, event: @event, overrides: {})
    WaitingRoomEntry.new({ user: user, event: event, status: :waiting }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid waiting room entry" do
    entry = build_entry
    assert entry.valid?
    assert entry.save
  end

  test "user_id must be unique per event" do
    WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    duplicate = WaitingRoomEntry.new(user: @alice, event: @event, status: :waiting)
    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "same user can join different events" do
    other_event = Event.create!(
      name: "Other Event",
      venue: @event.venue,
      organizer: @event.organizer,
      status: :published,
      seat_selection_mode: :none,
      starts_at: 2.weeks.from_now,
      ends_at: 2.weeks.from_now + 2.hours
    )
    e1 = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    e2 = WaitingRoomEntry.new(user: @alice, event: other_event, status: :waiting)
    assert e2.valid?
  end

  # ── admit! ──────────────────────────────────────────────────────────────────

  test "admit! transitions status to admitted and sets token and timestamps" do
    entry = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    entry.admit!

    assert entry.admitted?
    assert entry.admission_token.present?
    assert entry.admitted_at.present?
    assert entry.expires_at.present?
    assert_operator entry.expires_at, :>, Time.current
  end

  # ── admission_expired? ───────────────────────────────────────────────────────

  test "admission_expired? is false for a waiting entry" do
    entry = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    refute entry.admission_expired?
  end

  test "admission_expired? is false when admitted but not yet expired" do
    entry = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    entry.admit!
    refute entry.admission_expired?
  end

  test "admission_expired? is true when admitted and expires_at is in the past" do
    entry = WaitingRoomEntry.create!(
      user: @alice, event: @event, status: :admitted,
      admission_token: SecureRandom.urlsafe_base64(32),
      admitted_at: 20.minutes.ago,
      expires_at: 5.minutes.ago
    )
    assert entry.admission_expired?
  end

  # ── minutes_remaining ────────────────────────────────────────────────────────

  test "minutes_remaining returns 0 when entry is not admitted" do
    entry = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    assert_equal 0, entry.minutes_remaining
  end

  test "minutes_remaining returns positive value when admitted and not expired" do
    entry = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    entry.admit!
    assert_operator entry.minutes_remaining, :>=, 0
  end

  # ── queue_position & total_waiting ──────────────────────────────────────────

  test "queue_position reflects order of entry" do
    e1 = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    e2 = WaitingRoomEntry.create!(user: @bob,   event: @event, status: :waiting)

    assert_equal 1, e1.queue_position
    assert_equal 2, e2.queue_position
  end

  test "total_waiting counts only waiting entries" do
    e1 = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    e1.admit!  # admitted, no longer waiting

    e2 = WaitingRoomEntry.create!(user: @bob, event: @event, status: :waiting)

    assert_equal 1, e2.total_waiting
  end

  # ── active_queue scope ───────────────────────────────────────────────────────

  test "active_queue scope returns only waiting entries ordered by created_at" do
    e1 = WaitingRoomEntry.create!(user: @alice, event: @event, status: :waiting)
    e2 = WaitingRoomEntry.create!(user: @bob,   event: @event, status: :waiting)
    e2.admit!  # remove from queue

    queue = @event.waiting_room_entries.active_queue.to_a
    assert_includes queue, e1
    assert_not_includes queue, e2
  end
end
