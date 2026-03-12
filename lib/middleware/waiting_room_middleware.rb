# frozen_string_literal: true

require_relative "waiting_room_page_renderer"

module Middleware
  # Rack middleware that gates access to event pages when a waiting room is active.
  #
  # For users in the queue (not yet admitted), serves a lightweight HTML page
  # directly from the middleware — bypassing the entire Rails stack.
  #
  # For admitted users (valid admission cookie + Redis token), passes the
  # request through to Rails for normal processing.
  #
  # For users not in any queue, passes through to Rails (they'll see the
  # normal event page with the "Join Waiting Room" button).
  #
  # Only intercepts GET/HEAD requests. POST/DELETE (join queue, leave queue,
  # create order) always pass through to Rails controllers.
  class WaitingRoomMiddleware
    EVENT_SHOW_PATTERN  = %r{\A/events/(\d+)\z}
    ORDER_PATHS_PATTERN = %r{\A/events/(\d+)/orders(?:/|\z)}

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      # Only intercept GET/HEAD requests
      return @app.call(env) unless request.get? || request.head?

      # Only intercept event show and order paths
      event_id = extract_event_id(request.path)
      return @app.call(env) unless event_id

      # Check if this event has an active waiting room (from Redis)
      config = WaitingRoomRedis.get("event:#{event_id}:config")
      return @app.call(env) unless config && config[:enabled]

      # Check if user has a valid admission token
      if admitted?(request, event_id)
        return @app.call(env) # Admitted — let Rails handle it
      end

      # For order paths, block unadmitted users
      if request.path.match?(ORDER_PATHS_PATTERN)
        return redirect_to_waiting_room(event_id)
      end

      # For event show page, check if user is in the queue
      if request.path.match?(EVENT_SHOW_PATTERN)
        entry_status = fetch_queue_entry(request, event_id)
        if entry_status && entry_status[:status] == "waiting"
          return serve_waiting_room_page(event_id, config, entry_status)
        end
        # Not in queue — pass through to Rails (normal event page)
      end

      @app.call(env)
    end

    private

    def extract_event_id(path)
      match = path.match(%r{\A/events/(\d+)})
      match && match[1].to_i
    end

    # Check if the user has a valid admission cookie and the token is valid in Redis
    def admitted?(request, event_id)
      cookie_value = request.cookies["_wr_admitted_#{event_id}"]
      return false unless cookie_value

      token = verify_cookie(cookie_value)
      return false unless token

      # Validate token in Redis
      token_data = WaitingRoomRedis.get("token:#{token}")
      return false unless token_data

      # Check not expired
      expires_at = Time.parse(token_data[:expires_at])
      expires_at > Time.current
    rescue ArgumentError, TypeError
      false
    end

    # Check if user is in the queue (has a queue cookie with valid entry in Redis)
    def fetch_queue_entry(request, event_id)
      cookie_value = request.cookies["_wr_queue_#{event_id}"]
      return nil unless cookie_value

      entry_id = verify_cookie(cookie_value)
      return nil unless entry_id

      WaitingRoomRedis.get("entry:#{entry_id}:status")
    end

    # Verify a signed cookie value using the app's secret
    def verify_cookie(value)
      message_verifier.verify(value)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def message_verifier
      @message_verifier ||= ActiveSupport::MessageVerifier.new(
        Rails.application.secret_key_base,
        digest: "SHA256",
        serializer: JSON
      )
    end

    # Serve the lightweight waiting room HTML page
    def serve_waiting_room_page(event_id, config, entry_status)
      html = WaitingRoomPageRenderer.render(
        event_id: event_id,
        event_name: config[:event_name],
        position: entry_status[:position],
        total: entry_status[:total],
        poll_url: "/events/#{event_id}/waiting_room/status"
      )

      [ 200, response_headers, [ html ] ]
    end

    # Redirect unadmitted users to the waiting room
    def redirect_to_waiting_room(event_id)
      [ 302, { "location" => "/events/#{event_id}/waiting_room", "content-type" => "text/html" }, [ "" ] ]
    end

    def response_headers
      {
        "content-type" => "text/html; charset=utf-8",
        "cache-control" => "no-cache, no-store, must-revalidate",
        "x-turbo-visit-control" => "reload"
      }
    end
  end
end
