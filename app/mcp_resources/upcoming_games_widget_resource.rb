# frozen_string_literal: true

class UpcomingGamesWidgetResource
  VERSION = "v4"
  URI = "ui://widget/upcoming-games.html?#{VERSION}"

  class << self
    def to_resource
      MCP::Resource.new(
        uri: URI,
        name: "Upcoming Games Widget",
        description: "Interactive schedule widget with ticket links",
        mime_type: "text/html+skybridge"
      )
    end

    def read
      ActionController::Base.render(
        template: "mcp_widgets/widget",
        layout: false,
        locals: {
          widget_title: "Upcoming Games",
          component_name: "UpcomingGamesWidget"
        }
      )
    end

    def meta
      base_url = ENV.fetch("BASE_URL", "http://localhost:3000")

      {
        "openai/widgetPrefersBorder" => true,
        "openai/widgetDomain" => "https://chatgpt.com",
        "openai/widgetCSP" => {
          "connect_domains" => [ "https://chatgpt.com", base_url ],
          "resource_domains" => [ base_url, "https://*.oaistatic.com" ]
        }
      }
    end
  end
end
