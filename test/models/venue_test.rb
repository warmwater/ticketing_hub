require "test_helper"

class VenueTest < ActiveSupport::TestCase
  setup do
    @creator = users(:organizer)
    @venue   = venues(:concert_hall)
  end

  def build_venue(overrides = {})
    Venue.new({
      name: "Test Venue",
      address: "123 Main St",
      created_by: @creator
    }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid venue" do
    venue = build_venue
    assert venue.valid?
  end

  test "requires name" do
    venue = build_venue(name: nil)
    assert_not venue.valid?
    assert_includes venue.errors[:name], "can't be blank"
  end

  test "requires address" do
    venue = build_venue(address: nil)
    assert_not venue.valid?
    assert_includes venue.errors[:address], "can't be blank"
  end

  test "capacity must be greater than 0 when provided" do
    venue = build_venue(capacity: 0)
    assert_not venue.valid?
    assert venue.errors[:capacity].any?
  end

  test "capacity can be nil" do
    venue = build_venue(capacity: nil)
    assert venue.valid?
  end

  test "capacity can be a positive number" do
    venue = build_venue(capacity: 500)
    assert venue.valid?
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  test "ordered scope returns venues alphabetically by name" do
    # Use names that sort before/after the fixture "Concert Hall"
    a_venue = Venue.create!(name: "Arena", address: "1 A St", created_by: @creator)
    z_venue = Venue.create!(name: "Zenith Stage", address: "1 Z St", created_by: @creator)

    ordered = Venue.ordered.pluck(:name)
    assert ordered.index("Arena") < ordered.index("Concert Hall")
    assert ordered.index("Concert Hall") < ordered.index("Zenith Stage")
  end

  # ── Methods ─────────────────────────────────────────────────────────────────

  test "has_seating? returns true when venue has sections" do
    assert @venue.has_seating?
  end

  test "has_seating? returns false when venue has no sections" do
    venue = Venue.create!(name: "Empty Venue", address: "99 Nowhere Ln", created_by: @creator)
    refute venue.has_seating?
  end
end
