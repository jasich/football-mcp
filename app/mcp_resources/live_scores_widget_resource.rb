# frozen_string_literal: true

class LiveScoresWidgetResource
  # Add version for cache busting during development
  VERSION = "v4"
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
        template: "mcp_widgets/live_scores",
        layout: false
      )
    end

    def meta
      {
        "openai/widgetPrefersBorder" => true,
        "openai/widgetDomain" => "https://chatgpt.com",
        "openai/widgetCSP" => {
          "connect_domains" => [ "https://chatgpt.com" ],
          "resource_domains" => [ "https://*.oaistatic.com" ]
        }
      }
    end
  end
end
