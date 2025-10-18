# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Rails 8 API-only application that implements a Model Context Protocol (MCP) server for American football data. The app uses the official Ruby MCP SDK (https://github.com/modelcontextprotocol/ruby-sdk) with **Streamable HTTP transport**, providing full support for the OpenAI Apps SDK.

### OpenAI Apps SDK Support

This server is **fully compatible with the OpenAI Apps SDK** (announced at DevDay 2025). It supports:
- **Streamable HTTP transport** - The recommended transport for ChatGPT integration
- **Server-Sent Events (SSE)** - Real-time streaming of tool responses
- **Session management** - Proper handling of multiple concurrent clients
- **Production-ready** - Can be deployed to serverless platforms (AWS Lambda, Vercel, Cloudflare Workers)

## Development Commands

**Start the server:**
```bash
bundle install
rails server
```

**Run tests:**
```bash
rails test
```

**Run linter:**
```bash
rubocop
```

**Test MCP endpoint (non-streaming):**
```bash
# List available tools
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'

# Call a tool
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_live_scores_tool","arguments":{}}}'
```

**Test with SSE streaming:**
```bash
# 1. Initialize a session
curl -i http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'

# Note the Mcp-Session-Id header in the response

# 2. Connect to SSE stream (in one terminal)
curl -N -H "Mcp-Session-Id: YOUR_SESSION_ID" http://localhost:3000/mcp

# 3. Call tools (responses will stream to terminal #2)
curl -i http://localhost:3000/mcp \
  -H "Mcp-Session-Id: YOUR_SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","id":2,"params":{"name":"get_live_scores_tool","arguments":{}}}'

# Returns {"accepted":true} and response goes to SSE stream

# 4. Clean up session
curl -X DELETE http://localhost:3000/mcp \
  -H "Mcp-Session-Id: YOUR_SESSION_ID"
```

**For ChatGPT/OpenAI Apps SDK:**
```bash
# Use ngrok for HTTPS during development
ngrok http 3000

# Then configure your OpenAI App to use the ngrok URL
```

## Architecture

### MCP Server Pattern

The application uses **Streamable HTTP transport** which supports multiple HTTP methods at the `/mcp` endpoint:

**HTTP Methods:**
- **POST** - JSON-RPC requests (initialize, tools/list, tools/call, etc.)
- **GET** - SSE stream connections (requires Mcp-Session-Id header)
- **DELETE** - Session cleanup (requires Mcp-Session-Id header)

**Request Flow:**
1. **Routes** (`config/routes.rb:12-14`): All three HTTP methods route to `McpController#handle`
2. **Controller** (`app/controllers/mcp_controller.rb:8-33`):
   - Uses singleton pattern to maintain a single `StreamableHTTPTransport` instance across requests
   - This preserves session state for SSE connections
   - Delegates all request handling to `transport.handle_request(request)`
   - The transport automatically handles POST/GET/DELETE based on request method
3. **Tools** (`app/mcp_tools/`): Each tool is a class that inherits from `MCP::Tool`

**Session Management:**
- Sessions are created via the `initialize` JSON-RPC method
- Server returns a `Mcp-Session-Id` header containing a UUID
- Clients use this session ID to establish SSE streams and make subsequent requests
- When an SSE stream is active, tool responses are sent via SSE and HTTP returns `{"accepted":true}`
- Without an active stream, responses return normally as JSON

### Adding New Tools

1. Create a new tool class in `app/mcp_tools/`:
   - Inherit from `MCP::Tool`
   - Define `title` and `description`
   - Define `input_schema` with JSON Schema format
   - Implement `self.call` method that returns `MCP::Tool::Response.new([content])`
   - The `server_context` parameter is available but currently unused

2. Register the tool in `app/controllers/mcp_controller.rb:42` by adding it to the `tools:` array in the `create_transport` method

**Example tool structure:**
```ruby
class MyTool < MCP::Tool
  title "My Tool"
  description "What this tool does"

  input_schema(
    type: "object",
    properties: { param: { type: "string" } },
    required: ["param"]
  )

  def self.call(param:, server_context: nil)
    MCP::Tool::Response.new([{ "type" => "text", "text" => "Result: #{param}" }])
  end
end
```

### Current Tools

- **GetLiveScoresTool** (`app/mcp_tools/get_live_scores_tool.rb`): Returns mock live football scores with optional league filtering. Demonstrates response formatting and data filtering patterns.

### Technology Stack

- Rails 8.0.2+ (API-only mode)
- Ruby MCP SDK gem with StreamableHTTPTransport
- SQLite 3 with Solid adapters (solid_cache, solid_queue, solid_cable)
- Puma web server

## Production Deployment

### For OpenAI Apps SDK / ChatGPT Integration

**Requirements:**
- HTTPS endpoint (ChatGPT requires secure connections)
- Low cold-start latency
- CORS headers to allow `chatgpt.com`

**Development with ngrok:**
```bash
# Install ngrok: https://ngrok.com/download
ngrok http 3000

# Use the HTTPS URL in your OpenAI App configuration
```

**Production Platforms:**
- AWS Lambda with API Gateway
- Vercel
- Cloudflare Workers
- Heroku
- Fly.io
- Any platform supporting long-lived HTTP connections for SSE

**Security Considerations:**
- Implement authentication via custom headers or bearer tokens
- Restrict CORS to only allow `chatgpt.com` for ChatGPT apps
- Consider rate limiting for production use
- Monitor session count and implement cleanup for abandoned sessions

### Sending Real-time Updates

To push notifications to connected SSE clients (e.g., live score updates):

```ruby
# In your tool or background job
server.notify_tools_list_changed  # Notify when tools change
server.notify_prompts_list_changed  # Notify when prompts change
server.notify_resources_list_changed  # Notify when resources change
```

Note: The transport instance must be accessible to send notifications. Consider making it available via a global registry or singleton pattern for background jobs.
