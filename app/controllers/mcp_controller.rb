# frozen_string_literal: true

class McpController < ApplicationController
  def handle
    server = MCP::Server.new(
      name: "football-mcp-server",
      version: "1.0.0",
      instructions: "A Rails-based MCP server for American football data",
      tools: [GetLiveScoresTool]
    )

    render json: server.handle_json(request.body.read)
  end
end
