# frozen_string_literal: true

class McpController < ApplicationController
  # Store transport instance in class variable to maintain sessions across requests
  #
  # WARNING: This singleton pattern with in-memory session storage is NOT suitable for production!
  # Issues:
  # - Sessions lost on server restart/deployment
  # - Won't work with multiple servers/processes (no horizontal scaling)
  # - No session cleanup for abandoned connections (memory leak)
  # - SSE streams are process-bound
  #
  # For production, consider:
  # - Stateless mode (no sessions) for serverless deployments
  # - Redis/database-backed session storage with sticky sessions
  # - Dedicated SSE service (Node.js/Go) with pub/sub
  #
  # This approach is fine for:
  # - Development/testing
  # - Single-server deployments
  # - Demo applications
  @@transport = nil
  @@transport_mutex = Mutex.new

  def handle
    # Get or create the transport instance (singleton pattern for session persistence)
    transport = @@transport_mutex.synchronize do
      @@transport ||= create_transport
    end

    # Handle the request using StreamableHTTPTransport
    # Supports POST (JSON-RPC), GET (SSE streams), DELETE (session cleanup)
    status, headers, body = transport.handle_request(request)

    # Rails expects body to be a string or array of strings
    body_content = if body.is_a?(Proc)
      # For SSE streams, Rails will handle the proc
      body
    elsif body.is_a?(Array)
      body.join
    else
      body.to_s
    end

    # Set response headers
    headers.each { |key, value| response.headers[key] = value }

    # Render the response
    render body: body_content, status: status
  end

  private

  def create_transport
    server = MCP::Server.new(
      name: "football-mcp-server",
      version: "1.0.0",
      instructions: "A Rails-based MCP server for American football data",
      tools: [GetLiveScoresTool],
      resources: [LiveScoresBoardResource.to_resource]
    )

    # Handle resources/read requests
    server.resources_read_handler do |params|
      uri = params[:uri]

      case uri
      when LiveScoresBoardResource::URI
        [{
          uri: uri,
          mimeType: "text/plain",
          text: LiveScoresBoardResource.read
        }]
      else
        raise MCP::Server::RequestHandlerError.new(
          "Resource not found: #{uri}",
          params,
          error_type: :resource_not_found
        )
      end
    end

    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
    server.transport = transport
    transport
  end
end
