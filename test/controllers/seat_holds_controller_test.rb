require "test_helper"

class SeatHoldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @event = events(:concert)
    @seat  = seats(:a1)
    @seat2 = seats(:a2)
    @seat3 = seats(:a3)
  end

  # ── Authentication ──────────────────────────────────────────────────────────

  test "create requires authentication" do
    post seat_holds_path, params: { seat_id: @seat.id, event_id: @event.id }, as: :json
    assert_response :unauthorized  # Devise returns 401 for JSON requests
  end

  test "destroy requires authentication" do
    hold = SeatHold.create!(
      seat: @seat, user: @alice, event: @event,
      expires_at: 10.minutes.from_now
    )
    delete seat_hold_path(hold), as: :json
    assert_response :unauthorized
  end

  # ── POST /seat_holds (create) ───────────────────────────────────────────────

  test "create succeeds and returns hold_id" do
    sign_in @alice

    assert_difference "SeatHold.count", 1 do
      post seat_holds_path,
           params: { seat_id: @seat.id, event_id: @event.id },
           as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["hold_id"].present?
    assert json["expires_at"].present?
    assert json["seconds_remaining"].present?
    assert_operator json["seconds_remaining"], :>, 0
  end

  test "create returns conflict when seat is already taken (has confirmed ticket)" do
    sign_in @alice

    # Simulate a confirmed ticket on the seat
    order = Order.create!(user: @alice, event: @event, status: :confirmed, total_amount: 50)
    tt = ticket_types(:orchestra_ticket)
    oi = order.order_items.create!(ticket_type: tt, quantity: 1, unit_price: 50)
    oi.tickets.create!(
      seat: @seat, barcode: SecureRandom.hex(16), status: :active,
      attendee_name: "Alice", attendee_email: "alice@example.com",
      section_name: "Orchestra", row_label: "A", seat_number: 1
    )

    post seat_holds_path,
         params: { seat_id: @seat.id, event_id: @event.id },
         as: :json

    assert_response :conflict
    json = JSON.parse(response.body)
    assert_equal "taken", json["error"]
  end

  test "create returns conflict when seat is held by another user" do
    SeatHold.create!(
      seat: @seat, user: @bob, event: @event,
      expires_at: 10.minutes.from_now
    )

    sign_in @alice
    post seat_holds_path,
         params: { seat_id: @seat.id, event_id: @event.id },
         as: :json

    assert_response :conflict
    json = JSON.parse(response.body)
    assert_equal "held", json["error"]
  end

  test "create refreshes existing hold idempotently" do
    sign_in @alice

    hold = SeatHold.create!(
      seat: @seat, user: @alice, event: @event,
      expires_at: 2.minutes.from_now
    )

    assert_no_difference "SeatHold.count" do
      post seat_holds_path,
           params: { seat_id: @seat.id, event_id: @event.id },
           as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal hold.id, json["hold_id"]

    # Expiration should be refreshed (extended)
    hold.reload
    assert_operator hold.expires_at, :>, 9.minutes.from_now
  end

  test "create releases expired holds before checking" do
    expired_hold = SeatHold.create!(
      seat: @seat, user: @bob, event: @event,
      expires_at: 1.minute.ago
    )

    sign_in @alice
    post seat_holds_path,
         params: { seat_id: @seat.id, event_id: @event.id },
         as: :json

    # Should succeed because Bob's hold expired
    assert_response :created
    refute SeatHold.exists?(expired_hold.id)
  end

  # ── DELETE /seat_holds/:id (destroy) ────────────────────────────────────────

  test "destroy releases hold and returns success" do
    sign_in @alice
    hold = SeatHold.create!(
      seat: @seat, user: @alice, event: @event,
      expires_at: 10.minutes.from_now
    )

    assert_difference "SeatHold.count", -1 do
      delete seat_hold_path(hold), as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "released", json["status"]
  end

  test "destroy returns not_found for another user's hold" do
    hold = SeatHold.create!(
      seat: @seat, user: @bob, event: @event,
      expires_at: 10.minutes.from_now
    )

    sign_in @alice
    delete seat_hold_path(hold), as: :json

    assert_response :not_found
    # Hold should still exist
    assert SeatHold.exists?(hold.id)
  end

  test "destroy returns not_found for nonexistent hold" do
    sign_in @alice
    delete seat_hold_path(id: 999999), as: :json
    assert_response :not_found
  end
end
