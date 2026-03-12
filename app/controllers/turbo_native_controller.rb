class TurboNativeController < ApplicationController
  def path_configuration
    render json: {
      settings: {
        screenshots_enabled: true,
        tabs: [
          { title: "Events", image_name: "calendar", path: "/events" },
          { title: "Tickets", image_name: "ticket", path: "/tickets", requires_authentication: true },
          { title: "Orders", image_name: "bag", path: "/orders", requires_authentication: true }
        ]
      },
      rules: [
        {
          patterns: [ "/new$", "/edit$" ],
          properties: { presentation: "modal" }
        },
        {
          patterns: [ "/sign_in", "/sign_up", "/password" ],
          properties: { presentation: "modal" }
        },
        {
          patterns: [ "/waiting_room" ],
          properties: {
            presentation: "default",
            pull_to_refresh_enabled: false
          }
        },
        {
          patterns: [ ".*" ],
          properties: {
            presentation: "default",
            pull_to_refresh_enabled: true
          }
        }
      ]
    }
  end
end
