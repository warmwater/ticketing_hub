require "test_helper"

class TicketTypeTest < ActiveSupport::TestCase
  setup do
    @event   = events(:concert)
    @section = sections(:orchestra)
    @tt      = ticket_types(:orchestra_ticket)
  end

  def build_tt(overrides = {})
    TicketType.new({
      name: "General Admission",
      event: @event,
      price: 25.00,
      quantity: 100,
      max_per_order: 4
    }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid ticket type" do
    tt = build_tt
    assert tt.valid?
  end

  test "requires name" do
    tt = build_tt(name: nil)
    assert_not tt.valid?
    assert_includes tt.errors[:name], "can't be blank"
  end

  test "price must be >= 0" do
    tt = build_tt(price: -1)
    assert_not tt.valid?
    assert tt.errors[:price].any?
  end

  test "price can be 0 (free ticket)" do
    tt = build_tt(price: 0)
    assert tt.valid?
  end

  test "quantity must be greater than 0" do
    tt = build_tt(quantity: 0)
    assert_not tt.valid?
    assert tt.errors[:quantity].any?
  end

  test "max_per_order must be greater than 0" do
    tt = build_tt(max_per_order: 0)
    assert_not tt.valid?
    assert tt.errors[:max_per_order].any?
  end

  # ── on_sale? ────────────────────────────────────────────────────────────────

  test "on_sale? returns true when no sale dates set" do
    assert @tt.on_sale?
  end

  test "on_sale? returns false when sale has not started yet" do
    @tt.sale_starts_at = 1.day.from_now
    @tt.sale_ends_at   = 2.days.from_now
    refute @tt.on_sale?
  end

  test "on_sale? returns false when sale has already ended" do
    @tt.sale_starts_at = 2.days.ago
    @tt.sale_ends_at   = 1.day.ago
    refute @tt.on_sale?
  end

  test "on_sale? returns true during active sale window" do
    @tt.sale_starts_at = 1.day.ago
    @tt.sale_ends_at   = 1.day.from_now
    assert @tt.on_sale?
  end

  # ── on_sale scope ───────────────────────────────────────────────────────────

  test "on_sale scope returns ticket types currently on sale" do
    tt_not_started = build_tt(name: "Future", sale_starts_at: 1.day.from_now).tap(&:save!)
    tt_ended       = build_tt(name: "Past", sale_starts_at: 2.days.ago, sale_ends_at: 1.day.ago).tap(&:save!)

    on_sale_ids = TicketType.on_sale.pluck(:id)
    assert_includes on_sale_ids, @tt.id
    assert_not_includes on_sale_ids, tt_not_started.id
    assert_not_includes on_sale_ids, tt_ended.id
  end

  # ── available_quantity & available? ─────────────────────────────────────────

  test "available_quantity equals quantity when no tickets sold and no section constraint" do
    # Create a ticket type with no section so available_quantity = quantity
    tt = build_tt(name: "No Section", section: nil)
    tt.save!
    assert_equal tt.quantity, tt.available_quantity
  end

  test "available_quantity is capped by seated section available seats" do
    # @tt belongs to orchestra section which has 3 active seats (a1, a2, a3)
    # quantity is 20 but only 3 seats available → min(20, 3) = 3
    assert_equal 3, @tt.available_quantity
  end

  test "available_quantity decreases when a seat ticket is sold" do
    seat  = seats(:a1)
    user  = users(:alice)
    order = Order.create!(user: user, event: @event, status: :confirmed, total_amount: 50)
    oi    = order.order_items.create!(ticket_type: @tt, quantity: 1, unit_price: 50)
    oi.tickets.create!(
      seat: seat, barcode: SecureRandom.hex(16), status: :active,
      attendee_name: user.name, attendee_email: user.email,
      section_name: "Orchestra", row_label: seat.row_label, seat_number: seat.seat_number
    )

    # Now 2 seats remain available
    assert_equal 2, @tt.available_quantity
  end

  test "available? returns true when tickets are available" do
    assert @tt.available?
  end

  test "available? returns false when quantity column is exhausted" do
    tt = build_tt(name: "Sold Out", section: nil)
    tt.save!
    tt.update_column(:quantity, 0)
    refute tt.available?
  end
end
