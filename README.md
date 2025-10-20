# Football MCP Server

A Rails app that implements a [Model Context Protocol](https://modelcontextprotocol.io/) server for American football data using the [official Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk).

**✨ OpenAI Apps SDK Compatible** - This server uses Streamable HTTP transport with full support for Server-Sent Events (SSE), making it ready for ChatGPT integration.

## Setup

```bash
bundle install
npm install
cp .env.example .env
# Edit .env and set BASE_URL to your ngrok URL for ChatGPT testing
```

**Start the server:**
```bash
# For local testing only
rails server

# For ChatGPT integration with React widgets
# 1. Start ngrok to expose your server
ngrok http 3000

# 2. Update .env with your ngrok URL
# BASE_URL=https://your-url.ngrok-free.app

# 3. Start Rails server
rails server
```

**Build React widgets:**
```bash
# One-time build
npm run build

# Watch mode (rebuilds on changes)
npm run watch
```

## ChatGPT / OpenAI Apps SDK Integration

The server supports all features required by the OpenAI Apps SDK:
- ✅ Streamable HTTP transport
- ✅ Server-Sent Events (SSE)
- ✅ Session management
- ✅ Real-time tool responses
- ✅ React widgets with interactive UIs

### HTTPS Tunneling for Development

ChatGPT requires an HTTPS endpoint to connect to your local development server. You have several options:

**Option 1: Cloudflare Tunnel (Recommended)**
- No browser warnings or interstitials
- Works with your own domain
- Free tier available
- Install `cloudflared` and run: `cloudflared tunnel --url http://localhost:3000`
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

After setting up your tunnel, update `.env` with your tunnel URL:
```bash
BASE_URL=https://your-tunnel-url.example.com
```

Then restart your Rails server for the changes to take effect.

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

## Adding React Widgets

This server includes React 19 for building interactive UI widgets that display inside ChatGPT.

### Quick Start

**1. Create a React component in `app/javascript/components/`:**

```jsx
// app/javascript/components/MyWidget.jsx
import React, { useSyncExternalStore } from 'react';

// Hook to reactively read tool output from ChatGPT
const SET_GLOBALS_EVENT_TYPE = 'openai:set_globals';

function useToolOutput() {
  return useSyncExternalStore(
    (onChange) => {
      const handleSetGlobal = (event) => {
        if (event.detail?.globals?.toolOutput === undefined) return;
        onChange();
      };
      window.addEventListener(SET_GLOBALS_EVENT_TYPE, handleSetGlobal, { passive: true });
      return () => window.removeEventListener(SET_GLOBALS_EVENT_TYPE, handleSetGlobal);
    },
    () => window.openai?.toolOutput
  );
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

**2. Register in `app/javascript/application.js`:**

```javascript
import React from 'react';
import { createRoot } from 'react-dom/client';
import MyWidget from './components/MyWidget';

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('react-root');
  if (container) {
    const root = createRoot(container);
    root.render(<MyWidget />);
  }
});
```

**3. Create an ERB view in `app/views/mcp_widgets/`:**

```erb
<!-- app/views/mcp_widgets/my_widget.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>My Widget</title>
  <%= javascript_include_tag "application", type: "module" %>
</head>
<body>
  <div id="react-root"></div>
</body>
</html>
```

**4. Create a resource in `app/mcp_resources/`:**

```ruby
# app/mcp_resources/my_widget_resource.rb
class MyWidgetResource
  VERSION = "v1"  # Increment when widget changes
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
      ActionController::Base.render(template: "mcp_widgets/my_widget", layout: false)
    end

    def meta
      base_url = ENV.fetch("BASE_URL", "http://localhost:3000")
      {
        "openai/widgetPrefersBorder" => true,
        "openai/widgetDomain" => "https://chatgpt.com",
        "openai/widgetCSP" => {
          "connect_domains" => ["https://chatgpt.com", base_url],
          "resource_domains" => [base_url, "https://*.oaistatic.com"]
        }
      }
    end
  end
end
```

**5. Register in `app/controllers/mcp_controller.rb`:**

```ruby
# Add to resources: array
resources: [LiveScoresWidgetResource.to_resource, MyWidgetResource.to_resource]

# Add to resources_read_handler
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

**6. Build and test:**

```bash
npm run build  # Rebuild JavaScript
# Increment VERSION to v2, v3, etc. when making changes to force ChatGPT to reload
```

### Asset Pipeline

The app uses Rails 8's modern asset pipeline:
- **jsbundling-rails** - JavaScript bundling with esbuild
- **Propshaft** - Asset serving with digest fingerprinting
- Assets build to `app/assets/builds/` (served by Propshaft at `/assets/`)
- `config.asset_host` generates full URLs for ChatGPT iframe loading
- CORS headers applied automatically via rack-cors middleware

## Architecture

This server uses the **Streamable HTTP transport** from the Ruby MCP SDK, which provides:

- **Multiple HTTP methods**: POST (JSON-RPC), GET (SSE streams), DELETE (session cleanup)
- **Session management**: UUID-based sessions with `Mcp-Session-Id` header
- **Dual-mode responses**: Standard JSON or SSE streaming based on active connections
- **Thread-safe**: Singleton transport instance with mutex-protected session storage
- **Keepalive**: Automatic ping messages every 30 seconds to maintain SSE connections

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.
