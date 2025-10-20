# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## Overview

This is a Rails 8 MCP (Model Context Protocol) server with React widgets for ChatGPT integration. See [README.md](README.md) for complete developer documentation.

## Key Patterns for AI Assistants

When modifying this codebase, follow these patterns:

### Resource Versioning (Critical!)

**ALWAYS increment the VERSION constant when modifying any resource:**

```ruby
class MyResource
  VERSION = "v2"  # ← Increment this EVERY TIME you change the resource
  URI = "my-resource://data?#{VERSION}"
end
```

ChatGPT caches resources aggressively. Without version bumps, clients will use stale cached versions indefinitely.

### Singleton Transport Pattern

The `McpController` uses a singleton pattern for the transport instance (`app/controllers/mcp_controller.rb:8-33`):

```ruby
@transport_mutex.synchronize do
  @transport ||= create_transport
end
```

**Never** create multiple transport instances. The singleton preserves SSE session state across requests.

### Shared Widget Template

All React widgets share `app/views/mcp_widgets/widget.html.erb`. Use the component registry pattern instead of creating new templates:

1. Add component to `COMPONENT_REGISTRY` in `app/javascript/application.js`
2. Use the shared template in resource's `read` method with `component_name` local

### File Locations

- **Tools**: `app/mcp_tools/` - Inherit from `MCP::Tool`
- **Resources**: `app/mcp_resources/` - Plain Ruby classes with `to_resource` and `read` methods
- **React Components**: `app/javascript/components/` - Export as default
- **MCP Controller**: `app/controllers/mcp_controller.rb` - Register tools/resources in `create_transport` method
- **Widget Template**: `app/views/mcp_widgets/widget.html.erb` - Shared by all widgets

### Registration Pattern

After creating a tool or resource, register it in `app/controllers/mcp_controller.rb`:

**For Tools:**
```ruby
tools: [GetLiveScoresTool, MyNewTool]
```

**For Resources:**
```ruby
# In create_transport
resources: [MyResource.to_resource, ...]

# In resources_read_handler
when MyResource::URI
  MyResource.read
```

### Asset Building

After modifying React components:
```bash
npm run build  # Or npm run watch for continuous rebuilding
```

Then increment the resource `VERSION` constant to force ChatGPT to reload.

## Common Tasks

### Adding a New Tool
1. Create class in `app/mcp_tools/` inheriting from `MCP::Tool`
2. Register in `McpController#create_transport` tools array
3. See [README.md#adding-tools](README.md#adding-tools) for details

### Adding a New Resource
1. Create class in `app/mcp_resources/` with `VERSION`, `URI`, `to_resource`, and `read` methods
2. Register in `McpController#create_transport` resources array
3. Add handler in `resources_read_handler` block
4. See [README.md#adding-resources](README.md#adding-resources) for details

### Adding a New React Widget
1. Create component in `app/javascript/components/`
2. Add to `COMPONENT_REGISTRY` in `app/javascript/application.js`
3. Create resource in `app/mcp_resources/` using shared template
4. Register resource in `McpController`
5. Run `npm run build`
6. See [README.md#adding-new-react-widgets](README.md#adding-new-react-widgets) for full step-by-step guide

## Development Commands

```bash
bin/dev           # Start Rails + JS watch + Cloudflare tunnel
rails server      # Start Rails only (local testing)
npm run build     # Build React widgets
npm run watch     # Build React widgets on file changes
rails test        # Run tests
rubocop          # Run linter
```

## Important Notes

- **Asset URLs**: Set `BASE_URL` in `.env` to your tunnel URL for ChatGPT integration
- **CORS**: Configured in `config/initializers/cors.rb` to allow `chatgpt.com`
- **Server Context**: The `server_context` parameter in tool calls is available but currently unused
- **Testing**: Always test tools via JSON-RPC before integrating with ChatGPT

## Documentation

For complete developer documentation, architecture details, and deployment instructions, see [README.md](README.md).
