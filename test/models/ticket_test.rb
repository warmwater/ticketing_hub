require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @user    = users(:alice)
    @event   = events(:concert)
    @seat    = seats(:a1)
    @tt      = ticket_types(:orchestra_ticket)
    @section = sections(:orchestra)

    @order = Order.create!(user: @user, event: @event, status: :confirmed, total_amount: 50)
    @oi    = @order.order_items.create!(ticket_type: @tt, quantity: 1, unit_price: 50)
  end

  def build_ticket(overrides = {})
    Ticket.new({
      order_item: @oi,
      attendee_name: @user.name,
      attendee_email: @user.email,
      status: :active
    }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid ticket and auto-generates barcode" do
    ticket = build_ticket
    assert ticket.valid?
    assert ticket.save
    assert ticket.barcode.present?
  end

  test "barcode is generated before validation on create" do
    ticket = build_ticket
    ticket.valid?
    assert ticket.barcode.present?
  end

  test "barcode must be unique" do
    ticket1 = build_ticket
    ticket1.save!

    ticket2 = build_ticket
    ticket2.barcode = ticket1.barcode
    assert_not ticket2.valid?
    assert_includes ticket2.errors[:barcode], "has already been taken"
  end

  # ── seat_not_double_booked ──────────────────────────────────────────────────

  test "seat_not_double_booked prevents duplicate active seat for same event" do
    ticket1 = build_ticket(seat: @seat, section_name: "Orchestra", row_label: "A", seat_number: 1)
    ticket1.save!

    # Build a second order+order_item so we can attach another ticket
    order2 = Order.create!(user: users(:bob), event: @event, status: :confirmed, total_amount: 50)
    oi2    = order2.order_items.create!(ticket_type: @tt, quantity: 1, unit_price: 50)
    ticket2 = Ticket.new(
      order_item: oi2,
      seat: @seat,
      section_name: "Orchestra", row_label: "A", seat_number: 1,
      attendee_name: users(:bob).name, attendee_email: users(:bob).email,
      status: :active
    )
    assert_not ticket2.valid?
    assert ticket2.errors[:seat].any?
  end

  test "cancelled ticket does not block rebooking the seat" do
    ticket1 = build_ticket(seat: @seat, section_name: "Orchestra", row_label: "A", seat_number: 1)
    ticket1.save!
    ticket1.update!(status: :cancelled)

    order2 = Order.create!(user: users(:bob), event: @event, status: :confirmed, total_amount: 50)
    oi2    = order2.order_items.create!(ticket_type: @tt, quantity: 1, unit_price: 50)
    ticket2 = Ticket.new(
      order_item: oi2,
      seat: @seat,
      section_name: "Orchestra", row_label: "A", seat_number: 1,
      attendee_name: users(:bob).name, attendee_email: users(:bob).email,
      status: :active
    )
    assert ticket2.valid?
  end

  # ── seat_label ──────────────────────────────────────────────────────────────

  test "seat_label with seat returns section, row and number" do
    ticket = build_ticket(
      seat: @seat,
      section_name: "Orchestra",
      row_label: "A",
      seat_number: 1
    )
    assert_equal "Orchestra — Row A, Seat 1", ticket.seat_label
  end

  test "seat_label without seat but with section_name returns general admission label" do
    ticket = build_ticket(section_name: "Orchestra")
    assert_equal "Orchestra (General Admission)", ticket.seat_label
  end

  test "seat_label returns nil when no seat and no section" do
    ticket = build_ticket
    assert_nil ticket.seat_label
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  test "valid_tickets scope returns only active tickets" do
    active_ticket   = build_ticket.tap(&:save!)
    pending_ticket  = build_ticket.tap { |t| t.status = :pending; t.save! }

    valid_ids = Ticket.valid_tickets.pluck(:id)
    assert_includes valid_ids, active_ticket.id
    assert_not_includes valid_ids, pending_ticket.id
  end
end
