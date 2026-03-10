class WaitingRoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :warm_event_cache

  def show
    @entry = @event.waiting_room_entries.find_by(user: current_user)

    if @entry&.admitted? && !@entry.admission_expired?
      # Set admission cookie so middleware passes them through to Rails
      set_admission_cookie(@entry)
      redirect_to new_event_order_path(@event), notice: "You're admitted! Complete your purchase."
      return
    end

    if @entry&.admission_expired?
      @entry.update!(status: :expired)
      @entry = nil
    end
  end

  def create
    entry = @event.waiting_room_entries.find_or_initialize_by(user: current_user)

    if entry.persisted? && entry.waiting?
      redirect_to event_waiting_room_path(@event), notice: "You're already in the waiting room."
      return
    end

    if entry.new_record? || entry.expired? || entry.left?
      entry.assign_attributes(status: :waiting, admission_token: nil, admitted_at: nil, expires_at: nil)
      entry.save!

      # Set the queue cookie for middleware to recognize this user
      set_queue_cookie(entry)

      # Trigger admission check
      AdmitNextUserJob.perform_later(@event.id)

      redirect_to event_waiting_room_path(@event), notice: "You've joined the waiting room."
    else
      redirect_to event_waiting_room_path(@event)
    end
  end

  def status
    @entry = @event.waiting_room_entries.find_by(user: current_user)

    respond_to do |format|
      format.turbo_stream
      format.json do
        if @entry
          # Set admission cookie when user is admitted (so middleware passes them through)
          if @entry.admitted? && !@entry.admission_expired?
            set_admission_cookie(@entry)
          end

          render json: {
            status: @entry.status,
            position: @entry.waiting? ? @entry.queue_position : nil,
            total: @entry.total_waiting,
            admitted: @entry.admitted? && !@entry.admission_expired?,
            expires_at: @entry.expires_at,
            purchase_url: @entry.admitted? ? new_event_order_path(@event) : nil
          }
        else
          render json: { status: "not_joined" }
        end
      end
    end
  end

  def destroy
    entry = @event.waiting_room_entries.find_by(user: current_user)
    entry&.update!(status: :left)
    clear_waiting_room_cookies
    redirect_to event_path(@event), notice: "You've left the waiting room."
  end

  private

  def set_event
    @event = Event.published.find(params[:event_id])
  end

  # Ensure the event's waiting room config is in Redis for the middleware
  def warm_event_cache
    Event.cache_waiting_room_config(@event) if @event.waiting_room_active?
  end

  # --- Cookie helpers for middleware integration ---

  def set_queue_cookie(entry)
    signed_value = message_verifier.generate(entry.id)
    cookies["_wr_queue_#{@event.id}"] = {
      value: signed_value,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?,
      path: "/events/#{@event.id}"
    }
  end

  def set_admission_cookie(entry)
    signed_value = message_verifier.generate(entry.admission_token)
    cookies["_wr_admitted_#{@event.id}"] = {
      value: signed_value,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?,
      expires: entry.expires_at,
      path: "/events/#{@event.id}"
    }
  end

  def clear_waiting_room_cookies
    cookies.delete("_wr_queue_#{@event.id}", path: "/events/#{@event.id}")
    cookies.delete("_wr_admitted_#{@event.id}", path: "/events/#{@event.id}")
  end

  def message_verifier
    @message_verifier ||= ActiveSupport::MessageVerifier.new(
      Rails.application.secret_key_base,
      digest: "SHA256",
      serializer: JSON
    )
  end
end
