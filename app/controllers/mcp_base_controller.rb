# frozen_string_literal: true

# Base controller for all MCP (Model Context Protocol) endpoints
# Disables CSRF protection since MCP uses header-based sessions, not cookies
class McpBaseController < ApplicationController
  # Disable CSRF protection for MCP JSON-RPC endpoints
  # MCP uses header-based sessions (Mcp-Session-Id), not cookies
  # CSRF attacks require cookie-based auth, which MCP doesn't use
  skip_before_action :verify_authenticity_token
end
