# frozen_string_literal: true

module Middleware
  # Generates a self-contained HTML page for the waiting room.
  # No ERB, no ActionView, no external assets — just inline CSS and JS.
  # This is served by the Rack middleware without touching Rails.
  class WaitingRoomPageRenderer
    def self.render(**kwargs)
      new(**kwargs).to_html
    end

    def initialize(event_id:, event_name:, position:, total:, poll_url:)
      @event_id = event_id
      @event_name = event_name
      @position = position || 0
      @total = total || 0
      @poll_url = poll_url
    end

    def to_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta name="turbo-visit-control" content="reload">
          <title>Waiting Room - #{h(@event_name)} | TicketHub</title>
          <style>#{inline_css}</style>
        </head>
        <body>
          #{header_html}
          <main>
            <div class="container">
              <div class="event-title">#{h(@event_name)}</div>
              <div class="subtitle">Virtual Waiting Room</div>

              <div class="card">
                <div class="spinner-wrap">
                  <div class="spinner"></div>
                </div>
                <div class="status-text">You're in line</div>
                <div class="position">
                  <span id="wr-position">#{@position}</span>
                </div>
                <div class="position-label">Your position in queue</div>

                <div class="progress-bar-wrap">
                  <div class="progress-bar" id="wr-progress" style="width: 5%"></div>
                </div>

                <div class="stats">
                  <span id="wr-total">#{@total}</span> people waiting
                </div>

                <p class="info">Please keep this page open. You'll be automatically redirected when it's your turn to purchase tickets.</p>

                <a href="/events/#{@event_id}/waiting_room" class="leave-link">Leave Queue</a>
              </div>

              <a href="/events/#{@event_id}" class="back-link">&larr; Back to Event</a>
            </div>
          </main>
          <script>#{inline_javascript}</script>
        </body>
        </html>
      HTML
    end

    private

    def h(text)
      Rack::Utils.escape_html(text.to_s)
    end

    def header_html
      <<~HTML
        <header>
          <a href="/" class="logo">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M15 5v2m0 4v2m0 4v2M5 5a2 2 0 00-2 2v3a2 2 0 110 4v3a2 2 0 002 2h14a2 2 0 002-2v-3a2 2 0 110-4V7a2 2 0 00-2-2H5z"/>
            </svg>
            <span>TicketHub</span>
          </a>
        </header>
      HTML
    end

    def inline_css
      <<~CSS
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
          background: #f9fafb;
          color: #111827;
          min-height: 100vh;
        }
        header {
          background: #fff;
          border-bottom: 1px solid #e5e7eb;
          padding: 0.75rem 1.5rem;
        }
        .logo {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          color: #4f46e5;
          text-decoration: none;
          font-weight: 800;
          font-size: 1.25rem;
        }
        main { padding: 2rem 1rem; }
        .container {
          max-width: 28rem;
          margin: 0 auto;
          text-align: center;
        }
        .event-title {
          font-size: 1.5rem;
          font-weight: 700;
          color: #111827;
          margin-bottom: 0.25rem;
        }
        .subtitle {
          color: #6b7280;
          font-size: 0.875rem;
          margin-bottom: 2rem;
        }
        .card {
          background: #fff;
          border-radius: 1rem;
          box-shadow: 0 4px 6px -1px rgba(0,0,0,.1), 0 2px 4px -2px rgba(0,0,0,.1);
          padding: 2rem 1.5rem;
          margin-bottom: 1.5rem;
        }
        .spinner-wrap {
          display: flex;
          justify-content: center;
          margin-bottom: 1.5rem;
        }
        .spinner {
          width: 48px;
          height: 48px;
          border: 4px solid #e5e7eb;
          border-top-color: #4f46e5;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .status-text {
          font-size: 0.875rem;
          font-weight: 600;
          color: #4f46e5;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          margin-bottom: 0.5rem;
        }
        .position {
          font-size: 3rem;
          font-weight: 800;
          color: #111827;
          line-height: 1;
          margin-bottom: 0.25rem;
        }
        .position-label {
          color: #6b7280;
          font-size: 0.875rem;
          margin-bottom: 1.5rem;
        }
        .progress-bar-wrap {
          background: #e5e7eb;
          border-radius: 9999px;
          height: 0.5rem;
          overflow: hidden;
          margin-bottom: 1rem;
        }
        .progress-bar {
          background: linear-gradient(90deg, #4f46e5, #7c3aed);
          height: 100%;
          border-radius: 9999px;
          transition: width 0.5s ease;
          min-width: 5%;
        }
        .stats {
          color: #6b7280;
          font-size: 0.875rem;
          margin-bottom: 1.5rem;
        }
        .info {
          color: #9ca3af;
          font-size: 0.8rem;
          line-height: 1.5;
          margin-bottom: 1.5rem;
        }
        .leave-link {
          color: #ef4444;
          font-size: 0.875rem;
          text-decoration: none;
          font-weight: 500;
        }
        .leave-link:hover { color: #dc2626; text-decoration: underline; }
        .back-link {
          color: #6b7280;
          font-size: 0.875rem;
          text-decoration: none;
        }
        .back-link:hover { color: #4f46e5; }

        /* Admitted state */
        .admitted { display: none; }
        .admitted.show { display: block; }
        .admitted .card {
          border: 2px solid #22c55e;
          background: #f0fdf4;
        }
        .admitted .check {
          color: #22c55e;
          margin-bottom: 1rem;
        }
        .purchase-btn {
          display: inline-block;
          background: #4f46e5;
          color: #fff;
          padding: 0.75rem 2rem;
          border-radius: 0.75rem;
          font-weight: 600;
          font-size: 1rem;
          text-decoration: none;
          transition: background 0.2s;
        }
        .purchase-btn:hover { background: #4338ca; }
      CSS
    end

    def inline_javascript
      <<~JS
        (function() {
          var pollUrl = "#{@poll_url}.json";
          var eventId = #{@event_id};
          var posEl = document.getElementById("wr-position");
          var totalEl = document.getElementById("wr-total");
          var progressEl = document.getElementById("wr-progress");

          function poll() {
            fetch(pollUrl, {
              credentials: "same-origin",
              headers: { "Accept": "application/json" }
            })
            .then(function(r) { return r.json(); })
            .then(function(data) {
              if (data.admitted === true && data.purchase_url) {
                // Admitted! Redirect to purchase page
                window.location.href = data.purchase_url;
                return;
              }
              if (data.position != null) {
                posEl.textContent = data.position;
              }
              if (data.total != null) {
                totalEl.textContent = data.total;
                // Update progress bar — closer to front = more progress
                var pct = data.total > 0 ? Math.max(5, Math.round(100 - (data.position / data.total * 100))) : 5;
                progressEl.style.width = pct + "%";
              }
              if (data.status === "not_joined" || data.status === "expired" || data.status === "left") {
                window.location.href = "/events/" + eventId;
              }
            })
            .catch(function(err) {
              console.warn("Waiting room poll error:", err);
            });
          }

          // Poll every 5 seconds
          setInterval(poll, 5000);
          // Initial poll after 2 seconds
          setTimeout(poll, 2000);
        })();
      JS
    end
  end
end
