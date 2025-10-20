# frozen_string_literal: true

class LiveScoresWidgetResource
  # Add version for cache busting during development
  # v5: React integration
  # v6: Replaced polling with proper OpenAI Apps SDK event listeners
  # v7: Inline JavaScript bundle to fix iframe loading
  # v8: Fix ERB escaping for inlined JS
  # v9: Use full URL with BASE_URL env var (matching OpenAI examples)
  # v10: Updated BASE_URL after server restart (cache bust)
  # v11: Added script_domains to CSP metadata (incorrect)
  # v12: Fixed CSP - added BASE_URL to resource_domains (correct way)
  # v13: Updated to Cloudflare Tunnel URL (local.theleashboss.com)
  # v14: Added CORS configuration for ChatGPT sandbox (incorrect wildcard)
  # v15: Fixed CORS regex pattern for oaiusercontent.com (still didn't work - static files)
  # v16: Serve JS through Rails controller for CORS middleware
  # v17: Added BASE_URL to connect_domains for sourcemap support
  VERSION = "v17"
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
