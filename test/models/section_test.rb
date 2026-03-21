require "test_helper"

class SectionTest < ActiveSupport::TestCase
  setup do
    @venue   = venues(:concert_hall)
    @event   = events(:concert)
    @section = sections(:orchestra)
  end

  def build_section(overrides = {})
    Section.new({
      name: "Balcony",
      venue: @venue,
      section_type: :seated,
      capacity: 50,
      position: 1
    }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid section" do
    section = build_section
    assert section.valid?
  end

  test "requires name" do
    section = build_section(name: nil)
    assert_not section.valid?
    assert_includes section.errors[:name], "can't be blank"
  end

  test "requires capacity" do
    section = build_section(capacity: nil)
    assert_not section.valid?
    assert section.errors[:capacity].any?
  end

  test "capacity must be greater than 0" do
    section = build_section(capacity: 0)
    assert_not section.valid?
    assert section.errors[:capacity].any?
  end

  test "name must be unique within venue" do
    # 'Orchestra' already exists in concert_hall
    section = build_section(name: "Orchestra")
    assert_not section.valid?
    assert section.errors[:name].any?
  end

  test "same name in different venues is allowed" do
    creator = users(:organizer)
    other_venue = Venue.create!(name: "Other Venue", address: "1 Other St", created_by: creator)
    section = Section.new(name: "Orchestra", venue: other_venue, section_type: :seated, capacity: 10, position: 0)
    assert section.valid?
  end

  test "position must be >= 0" do
    section = build_section(position: -1)
    assert_not section.valid?
    assert section.errors[:position].any?
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  test "ordered scope returns sections by position then name" do
    s1 = build_section(name: "Balcony", position: 2).tap(&:save!)
    s2 = build_section(name: "Mezzanine", position: 1).tap(&:save!)

    ordered = @venue.sections.ordered.to_a
    # orchestra is at position 0
    assert_equal sections(:orchestra), ordered.first
    assert_equal s2, ordered.second
    assert_equal s1, ordered.last
  end

  # ── Venue capacity callback ─────────────────────────────────────────────────

  test "saving section updates venue capacity" do
    new_section = build_section(capacity: 30)
    new_section.save!
    @venue.reload
    # 20 (orchestra) + 30 (balcony) = 50
    assert_equal 50, @venue.capacity
  end

  test "destroying section updates venue capacity" do
    extra = build_section(capacity: 30).tap(&:save!)
    @venue.reload
    assert_equal 50, @venue.capacity

    extra.destroy!
    @venue.reload
    assert_equal 20, @venue.capacity
  end

  # ── Methods ─────────────────────────────────────────────────────────────────

  test "active_seats returns only active seats" do
    active_count = @section.seats.where(active: true).count
    assert_equal active_count, @section.active_seats.count
  end

  test "available_seats_for_event excludes seats with active tickets" do
    available_before = @section.available_seats_for_event(@event).count
    assert_operator available_before, :>, 0

    # Create a confirmed order with a ticket on seat a1
    seat  = seats(:a1)
    user  = users(:alice)
    order = Order.create!(user: user, event: @event, status: :confirmed, total_amount: 50)
    tt    = ticket_types(:orchestra_ticket)
    oi    = order.order_items.create!(ticket_type: tt, quantity: 1, unit_price: 50)
    oi.tickets.create!(
      seat: seat, barcode: SecureRandom.hex(16), status: :active,
      attendee_name: user.name, attendee_email: user.email,
      section_name: @section.name, row_label: seat.row_label, seat_number: seat.seat_number
    )

    available_after = @section.available_seats_for_event(@event).count
    assert_equal available_before - 1, available_after
  end

  test "rows groups active seats by row_label" do
    rows = @section.rows
    assert_includes rows, "A"
    assert_equal 3, rows["A"].count
  end
end
