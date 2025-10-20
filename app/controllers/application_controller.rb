class ApplicationController < ActionController::Base
  # Disable CSRF protection for MCP JSON-RPC endpoints
  # (MCP clients don't use cookies/sessions)
  skip_before_action :verify_authenticity_token
end
