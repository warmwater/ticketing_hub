require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  setup do
    @user  = users(:alice)
    @event = events(:concert)
    @tt    = ticket_types(:orchestra_ticket)
    @order = Order.create!(user: @user, event: @event, status: :pending, total_amount: 0)
  end

  def build_item(overrides = {})
    OrderItem.new({
      order: @order,
      ticket_type: @tt,
      quantity: 2
    }.merge(overrides))
  end

  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid order item and sets unit_price from ticket_type" do
    item = build_item
    assert item.valid?
    item.save!
    assert_equal @tt.price, item.unit_price
  end

  test "quantity must be greater than 0" do
    item = build_item(quantity: 0)
    assert_not item.valid?
    assert item.errors[:quantity].any?
  end

  test "unit_price must be >= 0" do
    item = build_item
    item.unit_price = -1
    assert_not item.valid?
    assert item.errors[:unit_price].any?
  end

  # ── set_unit_price callback ──────────────────────────────────────────────────

  test "set_unit_price sets price from ticket_type when blank" do
    item = build_item
    item.valid?  # triggers before_validation
    assert_equal @tt.price, item.unit_price
  end

  test "set_unit_price does not override an explicitly set unit_price" do
    item = build_item(unit_price: 99.99)
    item.valid?
    assert_equal 99.99, item.unit_price
  end

  # ── total_price ─────────────────────────────────────────────────────────────

  test "total_price = quantity * unit_price" do
    item = build_item(quantity: 3)
    item.save!
    assert_equal 3 * @tt.price, item.total_price
  end
end
