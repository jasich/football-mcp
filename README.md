# Football MCP Server

A Rails app that implements a [Model Context Protocol](https://modelcontextprotocol.io/) server for American football data using the [official Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk).

## Setup

```bash
bundle install
rails server
```

## Usage

The MCP server is available at `POST /mcp`.

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

Register it in `app/controllers/mcp_controller.rb`:
```ruby
tools: [GetLiveScoresTool, MyTool]
```
