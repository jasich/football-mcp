# frozen_string_literal: true

class LiveScoresWidgetResource
  VERSION = "v1"
  URI = "ui://widget/live-scores.html?#{VERSION}"

  class << self
    def to_resource
      MCP::Resource.new(
        uri: URI,
        name: "Live Scores Widget",
        description: "HTML template for displaying live football scores",
        mime_type: "text/html+skybridge"
      )
    end

    def read
      ActionController::Base.render(
        template: "mcp_widgets/widget",
        layout: false,
        locals: {
          widget_title: "Live Football Scores",
          component_name: "LiveScoresWidget"
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
