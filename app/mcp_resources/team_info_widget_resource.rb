# frozen_string_literal: true

class TeamInfoWidgetResource
  # Add version for cache busting during development
  # v1: Initial version with team info widget
  # v2: Converted to Tailwind CSS with dark mode support
  VERSION = "v2"
  URI = "ui://widget/team-info.html?#{VERSION}"

  class << self
    def to_resource
      MCP::Resource.new(
        uri: URI,
        name: "Team Info Widget",
        description: "HTML template for displaying detailed team information",
        mime_type: "text/html+skybridge"
      )
    end

    def read
      ActionController::Base.render(
        template: "mcp_widgets/widget",
        layout: false,
        locals: {
          widget_title: "Team Information",
          component_name: "TeamInfoWidget"
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
