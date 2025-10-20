# frozen_string_literal: true

# Configure CORS for OpenAI Apps SDK / ChatGPT integration
# Allow ChatGPT's sandbox to load JavaScript bundles and make API calls

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from ChatGPT's web sandbox domains
    # The sandbox uses domains like: chatgpt-com.web-sandbox.oaiusercontent.com
    origins %r{https://.*\.oaiusercontent\.com}, "https://chatgpt.com"

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
