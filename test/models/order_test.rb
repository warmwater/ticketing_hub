require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @user  = users(:alice)
    @event = events(:concert)
    @tt    = ticket_types(:orchestra_ticket)
  end

  def build_order(overrides = {})
    Order.new({
      user: @user,
      event: @event,
      status: :pending,
      total_amount: 0
    }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid order with auto-generated reference_number" do
    order = build_order
    assert order.valid?
    assert order.save
    assert order.reference_number.present?
    assert_match /\AORD-/, order.reference_number
  end

  test "reference_number must be unique" do
    order1 = build_order.tap(&:save!)
    order2 = build_order
    order2.reference_number = order1.reference_number
    assert_not order2.valid?
    assert_includes order2.errors[:reference_number], "has already been taken"
  end

  test "reference_number is not overwritten if already set" do
    order = build_order
    order.reference_number = "ORD-CUSTOM01"
    order.save!
    assert_equal "ORD-CUSTOM01", order.reference_number
  end

  # ── Enums ───────────────────────────────────────────────────────────────────

  test "status enum values" do
    assert_equal 0, Order.statuses[:pending]
    assert_equal 1, Order.statuses[:confirmed]
    assert_equal 2, Order.statuses[:cancelled]
  end

  # ── calculate_total ──────────────────────────────────────────────────────────

  test "calculate_total sums order item totals" do
    order = build_order.tap(&:save!)
    order.order_items.create!(ticket_type: @tt, quantity: 2, unit_price: 50)
    order.order_items.create!(ticket_type: @tt, quantity: 1, unit_price: 30)
    order.calculate_total
    assert_equal 130, order.total_amount
  end

  # ── generate_tickets! ────────────────────────────────────────────────────────

  test "generate_tickets! creates tickets for each order item quantity" do
    order = build_order(status: :confirmed).tap(&:save!)
    oi    = order.order_items.create!(ticket_type: @tt, quantity: 2, unit_price: 50)

    assert_difference "Ticket.count", 2 do
      order.generate_tickets!
    end

    tickets = oi.tickets.reload
    assert_equal 2, tickets.count
    tickets.each do |t|
      assert_equal "active", t.status
      assert_equal @user.name, t.attendee_name
      assert_equal @user.email, t.attendee_email
    end
  end

  test "generate_tickets! assigns seat when seat_assignments provided" do
    seat  = seats(:a1)
    order = build_order(status: :confirmed).tap(&:save!)
    oi    = order.order_items.create!(ticket_type: @tt, quantity: 1, unit_price: 50)

    order.generate_tickets!(@tt.id.to_s => [ seat ])

    ticket = oi.tickets.first
    assert_equal seat, ticket.seat
    assert_equal seat.row_label, ticket.row_label
  end

  test "generate_tickets! rolls back if seat is already taken" do
    seat  = seats(:a1)
    # Book the seat via another order first
    other_order = Order.create!(user: users(:bob), event: @event, status: :confirmed, total_amount: 50)
    other_oi    = other_order.order_items.create!(ticket_type: @tt, quantity: 1, unit_price: 50)
    other_oi.tickets.create!(
      seat: seat, barcode: SecureRandom.hex(16), status: :active,
      attendee_name: users(:bob).name, attendee_email: users(:bob).email,
      section_name: "Orchestra", row_label: seat.row_label, seat_number: seat.seat_number
    )

    order = build_order(status: :confirmed).tap(&:save!)
    order.order_items.create!(ticket_type: @tt, quantity: 1, unit_price: 50)

    ticket_count_before = Ticket.count
    order.generate_tickets!(@tt.id.to_s => [ seat ])

    # The transaction rolled back so no new ticket was created
    assert_equal ticket_count_before, Ticket.count
  end
end
