class SeatHoldsController < ApplicationController
  before_action :authenticate_user!

  # POST /seat_holds
  # Body: { seat_id:, event_id: }
  def create
    seat  = Seat.find(params[:seat_id])
    event = Event.published.find(params[:event_id])

    # 1. Release expired holds first and broadcast those seats back to available
    SeatHold.release_expired_for_event!(event)

    # 2. Refuse if the seat already has a confirmed ticket
    if seat.taken_for_event?(event)
      render json: { error: "taken" }, status: :conflict and return
    end

    # 3. Check for an active hold
    existing = SeatHold.active.find_by(seat: seat, event: event)
    if existing.present? && existing.user != current_user
      render json: { error: "held" }, status: :conflict and return
    end

    # 4. Refresh the current user's existing hold (idempotent re-select)
    if existing.present? && existing.user == current_user
      existing.update!(expires_at: SeatHold::HOLD_DURATION.from_now)
      render json: { hold_id: existing.id, expires_at: existing.expires_at.iso8601,
                     seconds_remaining: existing.seconds_remaining }, status: :ok and return
    end

    # 5. Create a new hold
    hold = SeatHold.create!(
      seat: seat, user: current_user, event: event,
      expires_at: SeatHold::HOLD_DURATION.from_now
    )

    # Broadcast held state to all OTHER subscribers on this event's seat channel
    Turbo::StreamsChannel.broadcast_replace_to(
      "event_#{event.id}_seats",
      target: "seat_#{seat.id}",
      partial: "orders/held_seat",
      locals: { seat: seat }
    )

    render json: { hold_id: hold.id, expires_at: hold.expires_at.iso8601,
                   seconds_remaining: hold.seconds_remaining }, status: :created

  rescue ActiveRecord::RecordNotUnique
    # DB unique index fired — another request won the race
    render json: { error: "held" }, status: :conflict
  end

  # DELETE /seat_holds/:id
  def destroy
    hold = current_user.seat_holds.find(params[:id])
    seat  = hold.seat
    event = hold.event

    hold.destroy!
    SeatHold.broadcast_seat_available(seat, event)

    render json: { status: "released" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end
end
