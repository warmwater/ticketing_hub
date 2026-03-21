require "test_helper"

class SeatTest < ActiveSupport::TestCase
  setup do
    @section = sections(:orchestra)
    @event   = events(:concert)
    @seat    = seats(:a1)
  end

  def build_seat(overrides = {})
    Seat.new({
      section: @section,
      row_label: "B",
      seat_number: 1,
      active: true
    }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid seat" do
    seat = build_seat
    assert seat.valid?
  end

  test "requires row_label" do
    seat = build_seat(row_label: nil)
    assert_not seat.valid?
    assert_includes seat.errors[:row_label], "can't be blank"
  end

  test "requires seat_number" do
    seat = build_seat(seat_number: nil)
    assert_not seat.valid?
    assert seat.errors[:seat_number].any?
  end

  test "seat_number must be greater than 0" do
    seat = build_seat(seat_number: 0)
    assert_not seat.valid?
    assert seat.errors[:seat_number].any?
  end

  test "seat_number must be unique within section and row" do
    # a1 already occupies section=orchestra, row=A, seat_number=1
    seat = build_seat(row_label: "A", seat_number: 1)
    assert_not seat.valid?
    assert seat.errors[:seat_number].any?
  end

  test "same seat_number in different rows is allowed" do
    seat = build_seat(row_label: "C", seat_number: 1)
    assert seat.valid?
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  test "active scope returns only active seats" do
    inactive_seat = build_seat(row_label: "Z", seat_number: 99, active: false).tap(&:save!)
    active_ids = @section.seats.active.pluck(:id)

    assert_not_includes active_ids, inactive_seat.id
    assert_includes active_ids, @seat.id
  end

  test "ordered scope returns seats ordered by row then number" do
    ordered = @section.seats.ordered.to_a
    assert_equal seats(:a1), ordered.first
    assert_equal seats(:a2), ordered.second
    assert_equal seats(:a3), ordered.third
  end

  # ── Methods ─────────────────────────────────────────────────────────────────

  test "display_label uses label attribute when present" do
    @seat.label = "VIP-1"
    assert_equal "VIP-1", @seat.display_label
  end

  test "display_label falls back to row+number when label is blank" do
    @seat.label = nil
    assert_equal "A1", @seat.display_label
  end

  test "taken_for_event? returns false when no ticket exists" do
    refute @seat.taken_for_event?(@event)
  end

  test "taken_for_event? returns true when an active ticket exists" do
    user  = users(:alice)
    order = Order.create!(user: user, event: @event, status: :confirmed, total_amount: 50)
    tt    = ticket_types(:orchestra_ticket)
    oi    = order.order_items.create!(ticket_type: tt, quantity: 1, unit_price: 50)
    oi.tickets.create!(
      seat: @seat, barcode: SecureRandom.hex(16), status: :active,
      attendee_name: user.name, attendee_email: user.email,
      section_name: "Orchestra", row_label: "A", seat_number: 1
    )

    assert @seat.taken_for_event?(@event)
  end

  test "taken_for_event? returns false when only cancelled ticket exists" do
    user  = users(:alice)
    order = Order.create!(user: user, event: @event, status: :cancelled, total_amount: 50)
    tt    = ticket_types(:orchestra_ticket)
    oi    = order.order_items.create!(ticket_type: tt, quantity: 1, unit_price: 50)
    oi.tickets.create!(
      seat: @seat, barcode: SecureRandom.hex(16), status: :cancelled,
      attendee_name: user.name, attendee_email: user.email,
      section_name: "Orchestra", row_label: "A", seat_number: 1
    )

    refute @seat.taken_for_event?(@event)
  end
end
