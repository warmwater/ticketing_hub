require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ── Creation & Validations ──────────────────────────────────────────────────

  test "creates a valid user" do
    user = User.new(
      name: "Charlie",
      email: "charlie@example.com",
      password: "password123",
      role: :attendant
    )
    assert user.valid?
    assert user.save
  end

  test "requires name" do
    user = User.new(email: "x@example.com", password: "password123", role: :attendant)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "requires role" do
    user = User.new(name: "X", email: "x@example.com", password: "password123")
    user.role = nil
    assert_not user.valid?
    assert_includes user.errors[:role], "can't be blank"
  end

  test "requires email (devise validatable)" do
    user = User.new(name: "X", password: "password123", role: :attendant)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    User.create!(name: "Alice2", email: "unique@example.com", password: "password123", role: :attendant)
    duplicate = User.new(name: "Bob2", email: "unique@example.com", password: "password123", role: :attendant)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  # ── Role enum helpers ───────────────────────────────────────────────────────

  test "attendant? is true for attendant role" do
    alice = users(:alice)
    assert alice.attendant?
    refute alice.organizer?
    refute alice.admin?
  end

  test "organizer? is true for organizer role" do
    org = users(:organizer)
    assert org.organizer?
    refute org.attendant?
    refute org.admin?
  end

  test "admin? is true for admin role" do
    admin = User.create!(
      name: "Admin User",
      email: "admin@example.com",
      password: "password123",
      role: :admin
    )
    assert admin.admin?
    refute admin.attendant?
    refute admin.organizer?
  end
end
