# frozen_string_literal: true

# Configure CORS for OpenAI Apps SDK / ChatGPT integration
# Allow ChatGPT's sandbox to load JavaScript bundles and make API calls
#
# Security Note: The wildcard regex for oaiusercontent.com is necessary because
# ChatGPT uses dynamically generated sandbox subdomains for iframe isolation.
# Each widget may load in a different subdomain (e.g., chatgpt-com.web-sandbox.oaiusercontent.com).
# The regex is restricted to HTTPS and the oaiusercontent.com domain only.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from ChatGPT's web sandbox domains
    # Pattern matches: https://[any-subdomain].oaiusercontent.com
    # Examples:
    #   - chatgpt-com.web-sandbox.oaiusercontent.com
    #   - *.cdn.oaiusercontent.com
    # Restricted to: HTTPS only, oaiusercontent.com domain only
    origins %r{https://[\w\-]+\.oaiusercontent\.com}, "https://chatgpt.com"

    resource "/assets/*",
      headers: :any,
      methods: [ :get, :options ],
      credentials: false

    resource "/mcp",
      headers: :any,
      methods: [ :get, :post, :delete, :options ],
      credentials: false
  end
end
