# Football MCP Server

A Rails 8 application that implements a [Model Context Protocol](https://modelcontextprotocol.io/) server for American football data using the [official Ruby MCP SDK](https://github.com/modelcontextprotocol/ruby-sdk).

**✨ OpenAI Apps SDK Compatible** - This server uses Streamable HTTP transport with full support for Server-Sent Events (SSE), making it ready for ChatGPT integration with interactive React widgets.

## Features

- **Streamable HTTP transport** - The recommended transport for ChatGPT integration
- **Server-Sent Events (SSE)** - Real-time streaming of tool responses
- **Session management** - Proper handling of multiple concurrent clients
- **React 19 widgets** - Interactive UIs that render inside ChatGPT
- **Production-ready** - Can be deployed to serverless platforms (AWS Lambda, Vercel, Cloudflare Workers)

## Setup

```bash
bundle install
npm install
cp .env.example .env
# Edit .env and set BASE_URL to your tunnel URL for ChatGPT testing
```

**Start the server:**

```bash
# Recommended: Start everything with one command (Rails + JS build + Cloudflare Tunnel)
# Note: Requires cloudflared to be installed and configured
bin/dev

# Alternative: For local testing only (no HTTPS tunnel, no auto-rebuild)
rails server
```

**Build React widgets manually:**

```bash
# One-time build
npm run build

# Watch mode (rebuilds on changes) - not needed if using bin/dev
npm run watch
```

**Run tests:**

```bash
rails test
```

**Run linter:**

```bash
rubocop
```

## ChatGPT / OpenAI Apps SDK Integration

### HTTPS Tunneling for Development

ChatGPT requires an HTTPS endpoint to connect to your local development server. You have several options:

**Option 1: Cloudflare Tunnel (Recommended)**
- No browser warnings or interstitials
- Works with your own domain
- Free tier available
- Install `cloudflared` and configure in `Procfile.dev`:
  ```
  tunnel: cloudflared tunnel run your-tunnel-name
  ```
- More stable for long development sessions

**Option 2: ngrok (Paid Plan)**
- Free tier shows browser warnings that **break ChatGPT integration**
- Paid plans ($8+/month) remove the browser warning
- Simple setup: `ngrok http 3000`
- Good for quick testing with paid account

**Option 3: Other Tunneling Services**
- **localhost.run** - SSH-based tunneling, no installation required
- **Tailscale Funnel** - If you use Tailscale for networking
- **Bore** - Rust-based open source alternative
- **VS Code Port Forwarding** - If using GitHub Codespaces or VS Code Remote

**Important:** Free ngrok accounts show an interstitial "Visit Site" warning page that prevents ChatGPT from loading your resources. You'll need either a paid ngrok account or an alternative tunneling solution.

### Setting up for ChatGPT

1. **Configure your Cloudflare Tunnel** in `Procfile.dev`:
   ```
   tunnel: cloudflared tunnel run your-tunnel-name
   ```

2. **Start with `bin/dev`** - this will run Rails, JS watch, and your tunnel

3. **Find your tunnel URL** from the Cloudflare dashboard and update `.env`:
   ```
   BASE_URL=https://your-tunnel-url.com
   ```

4. **Restart `bin/dev`** for the BASE_URL change to take effect

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

### Technology Stack

- Rails 8.0.2+ (full Rails with API-only origins, now includes view support for widgets)
- Ruby MCP SDK gem with StreamableHTTPTransport
- SQLite 3 with Solid adapters (solid_cache, solid_queue, solid_cable)
- Puma web server
- React 19 for interactive widgets
- ESBuild for JavaScript bundling (via jsbundling-rails)
- Propshaft for asset serving
- dotenv-rails for environment configuration

## Adding Tools

Tools provide callable functions that clients can invoke.

### Step 1: Create a new tool class in `app/mcp_tools/`

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

### Step 2: Register the tool in `app/controllers/mcp_controller.rb`

Add it to the `tools:` array in the `create_transport` method:

```ruby
tools: [GetLiveScoresTool, MyTool]
```

### Current Tools

- **GetLiveScoresTool** (`app/mcp_tools/get_live_scores_tool.rb`): Returns mock live football scores with optional league filtering. Demonstrates response formatting and data filtering patterns.

## Adding Resources

Resources provide data that can be accessed by clients. They can be plain text, JSON, HTML widgets, or any other content type.

### Step 1: Create a new resource class in `app/mcp_resources/`

```ruby
class MyResource
  VERSION = "v1"  # Increment to v2, v3, etc. when content changes
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

### Step 2: Register the resource in `app/controllers/mcp_controller.rb`

Add `MyResource.to_resource` to the `resources:` array in `create_transport`:

```ruby
resources: [LiveScoresWidgetResource.to_resource, MyResource.to_resource]
```

Add a `when MyResource::URI` case in the `resources_read_handler` block:

```ruby
resources_read_handler: lambda { |uri, server_context|
  case uri
  when LiveScoresWidgetResource::URI
    LiveScoresWidgetResource.read
  when MyResource::URI
    MyResource.read
  else
    raise MCP::Error.new(
      code: MCP::JSONRPC::ErrorCodes::INVALID_PARAMS,
      message: "Unknown resource URI: #{uri}"
    )
  end
}
```

### Important: Resource Versioning

ChatGPT and other MCP clients cache resources aggressively. Always include a version parameter in your resource URI (e.g., `?v1`, `?v2`) and increment it whenever you modify the resource content:

```ruby
class MyResource
  VERSION = "v1"  # Increment to v2, v3, etc. when content changes
  URI = "my-resource://data?#{VERSION}"
end
```

Without versioning, clients will continue using stale cached versions indefinitely, even after server restarts.

### Current Resources

- **LiveScoresWidgetResource** (`app/mcp_resources/live_scores_widget_resource.rb`): HTML widget for displaying live football scores in ChatGPT. Demonstrates OpenAI Apps SDK widget integration with `text/html+skybridge` mime type.
- **TeamInfoResource** (`app/mcp_resources/team_info_resource.rb`): JSON resource providing NFL team information (names, divisions, colors, etc.).

## React Widget Architecture

The application uses React for building interactive UI widgets that render inside ChatGPT's iframe.

### Structure

- `app/javascript/components/` - React components
- `app/javascript/application.js` - Component registry and mounting logic
- `app/views/mcp_widgets/widget.html.erb` - **Shared widget template** (reused by all widgets)
- `app/assets/builds/` - Built JavaScript bundles (served by Propshaft)
- `.env` - BASE_URL configuration (sets `config.asset_host` for full URLs)

### Component Registry Pattern

All widgets share a single HTML template. The `application.js` file maintains a registry of React components and dynamically mounts the correct component based on the `data-component` attribute:

```javascript
const COMPONENT_REGISTRY = {
  'LiveScoresWidget': LiveScoresWidget,
  'TeamStatsWidget': TeamStatsWidget,  // Add new widgets here
};
```

This eliminates the need to create separate ERB templates for each widget.

### Asset Pipeline (Rails 8 Idiomatic)

- **jsbundling-rails** - Manages JavaScript bundling with esbuild
- **Propshaft** - Modern asset pipeline that serves files from `app/assets/builds/`
- esbuild builds to `app/assets/builds/` (not `public/`)
- Propshaft adds digest fingerprinting in production (e.g., `application-abc123.js`)
- Views use `javascript_include_tag "application"` which generates full URLs via `config.asset_host`
- CORS headers applied automatically by rack-cors middleware

### Key Patterns

- Uses `useOpenAiGlobal()` hook with `useSyncExternalStore` to reactively subscribe to `window.openai` changes
- Listens for `openai:set_globals` events instead of polling
- Reads tool output from `window.openai.toolOutput`

### Development Workflow

1. Edit React components in `app/javascript/components/`
2. Add component to registry in `app/javascript/application.js` (one line)
3. Run `npm run watch` to rebuild on changes (outputs to `app/assets/builds/`)
4. Increment resource `VERSION` constant to bust ChatGPT's cache
5. Test in ChatGPT (resource URI includes version, e.g., `ui://widget/live-scores.html?v19`)

## Adding New React Widgets

Adding a new widget requires only **6 steps**:
1. Create the React component
2. Add it to the component registry (one line in `application.js`)
3. Create a resource class that uses the shared template
4. Register the resource in the MCP controller
5. Rebuild assets
6. Test

**No separate ERB template needed!** All widgets share `app/views/mcp_widgets/widget.html.erb`.

### Step 1: Create a new React component

Create a component file in `app/javascript/components/`:

```jsx
// app/javascript/components/MyWidget.jsx
import React, { useSyncExternalStore } from 'react';

// Custom hook to subscribe to window.openai global changes
const SET_GLOBALS_EVENT_TYPE = 'openai:set_globals';

function useOpenAiGlobal(key) {
  return useSyncExternalStore(
    (onChange) => {
      const handleSetGlobal = (event) => {
        const value = event.detail?.globals?.[key];
        if (value === undefined) return;
        onChange();
      };

      window.addEventListener(SET_GLOBALS_EVENT_TYPE, handleSetGlobal, {
        passive: true,
      });

      return () => {
        window.removeEventListener(SET_GLOBALS_EVENT_TYPE, handleSetGlobal);
      };
    },
    () => window.openai?.[key]
  );
}

// Convenience hook for tool output
function useToolOutput() {
  return useOpenAiGlobal('toolOutput');
}

const MyWidget = () => {
  const toolOutput = useToolOutput();

  if (!toolOutput) {
    return <p>Waiting for data...</p>;
  }

  return (
    <div>
      <h2>My Widget</h2>
      <pre>{JSON.stringify(toolOutput, null, 2)}</pre>
    </div>
  );
};

export default MyWidget;
```

### Step 2: Register the component in `app/javascript/application.js`

Simply add your component to the `COMPONENT_REGISTRY`:

```javascript
import MyWidget from './components/MyWidget';

const COMPONENT_REGISTRY = {
  'LiveScoresWidget': LiveScoresWidget,
  'MyWidget': MyWidget,  // Add this line
};
```

### Step 3: Create a resource class in `app/mcp_resources/`

```ruby
# app/mcp_resources/my_widget_resource.rb
class MyWidgetResource
  VERSION = "v1"
  URI = "ui://widget/my-widget.html?#{VERSION}"

  class << self
    def to_resource
      MCP::Resource.new(
        uri: URI,
        name: "My Widget",
        description: "Custom widget for displaying data",
        mime_type: "text/html+skybridge"
      )
    end

    def read
      ActionController::Base.render(
        template: "mcp_widgets/widget",  # Shared template
        layout: false,
        locals: {
          widget_title: "My Widget",
          component_name: "MyWidget"  # Must match COMPONENT_REGISTRY key
        }
      )
    end

    def meta
      base_url = ENV.fetch("BASE_URL", "http://localhost:3000")

      {
        "openai/widgetPrefersBorder" => true,
        "openai/widgetDomain" => "https://chatgpt.com",
        "openai/widgetCSP" => {
          "connect_domains" => [ "https://chatgpt.com", base_url ],
          "resource_domains" => [ base_url, "https://*.oaistatic.com" ]
        }
      }
    end
  end
end
```

### Step 4: Register the resource in `app/controllers/mcp_controller.rb`

```ruby
# Add to the resources: array in create_transport
resources: [
  LiveScoresWidgetResource.to_resource,
  MyWidgetResource.to_resource
]

# Add to the resources_read_handler block
resources_read_handler: lambda { |uri, server_context|
  case uri
  when LiveScoresWidgetResource::URI
    LiveScoresWidgetResource.read
  when MyWidgetResource::URI
    MyWidgetResource.read
  else
    raise MCP::Error.new(
      code: MCP::JSONRPC::ErrorCodes::INVALID_PARAMS,
      message: "Unknown resource URI: #{uri}"
    )
  end
}
```

### Step 5: Rebuild assets and test

```bash
# Rebuild JavaScript
npm run build

# Increment VERSION in MyWidgetResource to v2, v3, etc. when making changes
# This forces ChatGPT to fetch the updated widget
```

### Step 6: Test in ChatGPT

Add your MCP server to ChatGPT, then reference your new resource in a conversation. ChatGPT will load your widget in an iframe.

## Production Deployment

### For OpenAI Apps SDK / ChatGPT Integration

**Requirements:**
- HTTPS endpoint (ChatGPT requires secure connections)
- Low cold-start latency
- CORS headers to allow `chatgpt.com`

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

## Testing

```bash
# Run all tests
rails test

# Run specific test file
rails test test/controllers/mcp_controller_test.rb

# Run with verbose output
rails test -v
```

## Project Structure

```
app/
├── controllers/
│   └── mcp_controller.rb          # Main MCP endpoint handler
├── mcp_tools/                      # MCP tool implementations
│   ├── get_live_scores_tool.rb
│   └── get_team_info_tool.rb
├── mcp_resources/                  # MCP resource implementations
│   ├── live_scores_widget_resource.rb
│   └── team_info_resource.rb
├── javascript/
│   ├── application.js              # Component registry & mounting
│   └── components/                 # React components
│       └── LiveScoresWidget.jsx
└── views/
    └── mcp_widgets/
        └── widget.html.erb         # Shared widget template

config/
├── routes.rb                       # MCP endpoint routes
└── initializers/
    └── cors.rb                     # CORS configuration

test/
└── controllers/
    └── mcp_controller_test.rb      # MCP endpoint tests
```

## License

MIT
