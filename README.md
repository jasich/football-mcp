# Football MCP Server

A Rails app that implements a [Model Context Protocol](https://modelcontextprotocol.io/) server for American football data using the [official Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk).

**✨ OpenAI Apps SDK Compatible** - This server uses Streamable HTTP transport with full support for Server-Sent Events (SSE), making it ready for ChatGPT integration.

## Setup

```bash
bundle install
rails server
```

## Usage

### Basic Usage (Non-Streaming)

The MCP server supports standard JSON-RPC requests:

**List tools:**
```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

**Get live scores:**
```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_live_scores_tool","arguments":{}}}'
```

**Filter by league:**
```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_live_scores_tool","arguments":{"league":"Pro League"}}}'
```

### Streaming with Server-Sent Events (SSE)

For real-time updates and ChatGPT integration:

**1. Initialize a session:**
```bash
curl -i http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```

Note the `Mcp-Session-Id` header in the response.

**2. Connect to SSE stream (in one terminal):**
```bash
curl -N -H "Mcp-Session-Id: YOUR_SESSION_ID" http://localhost:3000/mcp
```

**3. Call tools (in another terminal):**
```bash
curl -i http://localhost:3000/mcp \
  -H "Mcp-Session-Id: YOUR_SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","id":2,"params":{"name":"get_live_scores_tool","arguments":{}}}'
```

When an SSE stream is active, this returns `{"accepted":true}` and the response streams to the first terminal.

**4. Clean up session:**
```bash
curl -X DELETE http://localhost:3000/mcp \
  -H "Mcp-Session-Id: YOUR_SESSION_ID"
```

### ChatGPT / OpenAI Apps SDK Integration

For development with ChatGPT:

```bash
# Install ngrok for HTTPS tunneling
ngrok http 3000

# Use the HTTPS URL in your OpenAI App configuration
```

The server supports all features required by the OpenAI Apps SDK:
- ✅ Streamable HTTP transport
- ✅ Server-Sent Events (SSE)
- ✅ Session management
- ✅ Real-time tool responses

## Adding Tools

Create a file in `app/mcp_tools/`:

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

Register it in `app/controllers/mcp_controller.rb` in the `create_transport` method:
```ruby
tools: [GetLiveScoresTool, MyTool]
```

## Adding Resources

Resources provide data that can be accessed by clients. Create a file in `app/mcp_resources/`:

```ruby
class MyResource
  VERSION = "v1"  # Increment when content changes
  URI = "my-resource://data?#{VERSION}"

  class << self
    def to_resource
      MCP::Resource.new(
        uri: URI,
        name: "My Resource",
        description: "What this resource provides",
        mime_type: "text/plain"
      )
    end

    def read
      "Resource content here"
    end
  end
end
```

**Important: Resource Versioning**

ChatGPT and other MCP clients cache resources aggressively. Always include a version parameter in your resource URI (e.g., `?v1`, `?v2`) and increment it whenever you change the resource content. Without versioning, clients may continue using stale cached versions indefinitely.

Register it in `app/controllers/mcp_controller.rb`:
1. Add to the `resources:` array in `create_transport`
2. Add a case handler in `resources_read_handler` to return the content

## Architecture

This server uses the **Streamable HTTP transport** from the Ruby MCP SDK, which provides:

- **Multiple HTTP methods**: POST (JSON-RPC), GET (SSE streams), DELETE (session cleanup)
- **Session management**: UUID-based sessions with `Mcp-Session-Id` header
- **Dual-mode responses**: Standard JSON or SSE streaming based on active connections
- **Thread-safe**: Singleton transport instance with mutex-protected session storage
- **Keepalive**: Automatic ping messages every 30 seconds to maintain SSE connections

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.
