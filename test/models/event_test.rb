require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @organizer = users(:organizer)
    @venue     = venues(:concert_hall)
    @event     = events(:concert)
  end

  def build_event(overrides = {})
    Event.new({
      name: "Test Event",
      organizer: @organizer,
      venue: @venue,
      status: :published,
      seat_selection_mode: :none,
      starts_at: 1.week.from_now,
      ends_at: 1.week.from_now + 2.hours
    }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid event" do
    event = build_event
    assert event.valid?
  end

  test "requires name" do
    event = build_event(name: nil)
    assert_not event.valid?
    assert_includes event.errors[:name], "can't be blank"
  end

  test "requires starts_at" do
    event = build_event(starts_at: nil)
    assert_not event.valid?
    assert_includes event.errors[:starts_at], "can't be blank"
  end

  test "requires ends_at" do
    event = build_event(ends_at: nil)
    assert_not event.valid?
    assert_includes event.errors[:ends_at], "can't be blank"
  end

  test "ends_at must be after starts_at" do
    event = build_event(starts_at: 1.week.from_now, ends_at: 1.week.from_now - 1.hour)
    assert_not event.valid?
    assert_includes event.errors[:ends_at], "must be after start time"
  end

  test "ends_at equal to starts_at is invalid" do
    t = 1.week.from_now
    event = build_event(starts_at: t, ends_at: t)
    assert_not event.valid?
    assert_includes event.errors[:ends_at], "must be after start time"
  end

  test "max_tickets_per_user must be greater than 0 when set" do
    event = build_event(max_tickets_per_user: 0)
    assert_not event.valid?
    assert event.errors[:max_tickets_per_user].any?
  end

  test "max_tickets_per_user can be nil" do
    event = build_event(max_tickets_per_user: nil)
    assert event.valid?
  end

  # ── Enums ───────────────────────────────────────────────────────────────────

  test "status enum values" do
    assert_equal 0, Event.statuses[:draft]
    assert_equal 1, Event.statuses[:published]
    assert_equal 2, Event.statuses[:cancelled]
    assert_equal 3, Event.statuses[:completed]
  end

  test "seat_selection_mode enum values" do
    assert_equal 0, Event.seat_selection_modes[:none]
    assert_equal 1, Event.seat_selection_modes[:customer_pick]
    assert_equal 2, Event.seat_selection_modes[:auto_assign]
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  test "upcoming scope returns future events" do
    future_event = build_event(status: :draft).tap(&:save!)
    past_event   = build_event(
      name: "Past", starts_at: 2.weeks.ago, ends_at: 2.weeks.ago + 2.hours
    ).tap(&:save!)

    assert_includes Event.upcoming, future_event
    assert_not_includes Event.upcoming, past_event
  end

  test "published_events scope returns only published upcoming events" do
    published = build_event(status: :published).tap(&:save!)
    draft     = build_event(name: "Draft", status: :draft).tap(&:save!)

    assert_includes Event.published_events, published
    assert_not_includes Event.published_events, draft
  end

  # ── Business Logic ──────────────────────────────────────────────────────────

  test "total_capacity sums ticket_type quantities" do
    assert_equal 20, @event.total_capacity
  end

  test "tickets_sold counts active and used tickets" do
    assert_equal 0, @event.tickets_sold
  end

  test "tickets_available = total_capacity - tickets_sold" do
    assert_equal 20, @event.tickets_available
  end

  test "sold_out? is false when tickets are available" do
    refute @event.sold_out?
  end

  test "seated_event? is false for none mode" do
    @event.seat_selection_mode = :none
    refute @event.seated_event?
  end

  test "seated_event? is true for customer_pick mode" do
    assert @event.seated_event?
  end

  test "remaining_allowance_for returns nil when max_tickets_per_user is nil" do
    @event.max_tickets_per_user = nil
    assert_nil @event.remaining_allowance_for(users(:alice))
  end

  test "remaining_allowance_for returns max when user has no tickets" do
    @event.max_tickets_per_user = 4
    assert_equal 4, @event.remaining_allowance_for(users(:alice))
  end

  test "waiting_room_active? is false when waiting_room_enabled is false" do
    refute @event.waiting_room_active?
  end

  test "waiting_room_active? is false when event is not published" do
    event = build_event(status: :draft)
    event.waiting_room_enabled = true
    refute event.waiting_room_active?
  end
end
