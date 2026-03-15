require "test_helper"

class SeatHoldTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @event = events(:concert)
    @seat  = seats(:a1)
    @seat2 = seats(:a2)
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid seat hold" do
    hold = SeatHold.create!(
      seat: @seat, user: @alice, event: @event,
      expires_at: SeatHold::HOLD_DURATION.from_now
    )
    assert hold.persisted?
    assert hold.active?
    refute hold.expired?
  end

  test "enforces uniqueness on seat + event" do
    SeatHold.create!(
      seat: @seat, user: @alice, event: @event,
      expires_at: SeatHold::HOLD_DURATION.from_now
    )

    duplicate = SeatHold.new(
      seat: @seat, user: @bob, event: @event,
      expires_at: SeatHold::HOLD_DURATION.from_now
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:seat_id], "is already held for this event"
  end

  test "allows same seat for different events" do
    other_event = Event.create!(
      name: "Other Concert", venue: @event.venue, organizer: @event.organizer,
      status: :published, seat_selection_mode: :customer_pick,
      starts_at: 2.weeks.from_now, ends_at: 2.weeks.from_now + 3.hours
    )

    hold1 = SeatHold.create!(seat: @seat, user: @alice, event: @event, expires_at: 10.minutes.from_now)
    hold2 = SeatHold.create!(seat: @seat, user: @bob, event: other_event, expires_at: 10.minutes.from_now)

    assert hold1.persisted?
    assert hold2.persisted?
  end

  # ── Active / Expired ────────────────────────────────────────────────────────

  test "active? returns true when not expired" do
    hold = SeatHold.new(expires_at: 5.minutes.from_now)
    assert hold.active?
    refute hold.expired?
  end

  test "expired? returns true when past expiration" do
    hold = SeatHold.new(expires_at: 1.minute.ago)
    refute hold.active?
    assert hold.expired?
  end

  test "seconds_remaining is positive for active hold" do
    hold = SeatHold.new(expires_at: 5.minutes.from_now)
    assert_operator hold.seconds_remaining, :>, 200
    assert_operator hold.seconds_remaining, :<=, 300
  end

  test "seconds_remaining is zero for expired hold" do
    hold = SeatHold.new(expires_at: 1.minute.ago)
    assert_equal 0, hold.seconds_remaining
  end

  test "minutes_remaining rounds up" do
    hold = SeatHold.new(expires_at: 90.seconds.from_now)
    assert_equal 2, hold.minutes_remaining

    hold2 = SeatHold.new(expires_at: 59.seconds.from_now)
    assert_equal 1, hold2.minutes_remaining
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  test "active scope returns only unexpired holds" do
    active_hold = SeatHold.create!(
      seat: @seat, user: @alice, event: @event,
      expires_at: 10.minutes.from_now
    )
    expired_hold = SeatHold.create!(
      seat: @seat2, user: @alice, event: @event,
      expires_at: 1.minute.ago
    )

    actives = SeatHold.active
    assert_includes actives, active_hold
    assert_not_includes actives, expired_hold
  end

  test "expired scope returns only expired holds" do
    active_hold = SeatHold.create!(
      seat: @seat, user: @alice, event: @event,
      expires_at: 10.minutes.from_now
    )
    expired_hold = SeatHold.create!(
      seat: @seat2, user: @alice, event: @event,
      expires_at: 1.minute.ago
    )

    expireds = SeatHold.expired
    assert_not_includes expireds, active_hold
    assert_includes expireds, expired_hold
  end

  # ── release_expired_for_event! ──────────────────────────────────────────────

  test "release_expired_for_event! destroys expired holds for the event" do
    SeatHold.create!(
      seat: @seat, user: @alice, event: @event,
      expires_at: 1.minute.ago
    )
    SeatHold.create!(
      seat: @seat2, user: @bob, event: @event,
      expires_at: 10.minutes.from_now
    )

    assert_difference "SeatHold.count", -1 do
      SeatHold.release_expired_for_event!(@event)
    end

    # Active hold survives
    assert SeatHold.exists?(seat: @seat2, event: @event)
    # Expired hold is gone
    refute SeatHold.exists?(seat: @seat, event: @event)
  end

  # ── HOLD_DURATION ──────────────────────────────────────────────────────────

  test "HOLD_DURATION is 10 minutes" do
    assert_equal 10.minutes, SeatHold::HOLD_DURATION
  end
end
