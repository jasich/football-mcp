# frozen_string_literal: true

class LiveScoresWidgetResource
  # Add version for cache busting during development
  # v5: React integration
  # v6: Replaced polling with proper OpenAI Apps SDK event listeners
  # v7: Inline JavaScript bundle to fix iframe loading
  # v8: Fix ERB escaping for inlined JS
  # v9: Use full URL with BASE_URL env var (matching OpenAI examples)
  VERSION = "v9"
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
