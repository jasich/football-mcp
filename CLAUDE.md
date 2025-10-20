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

**Setup:**
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

**Run tests:**
```bash
rails test
```

**Run linter:**
```bash
rubocop
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

### Adding New Resources

1. Create a new resource class in `app/mcp_resources/`:
   - Define a `VERSION` constant and include it in the URI (e.g., `?v1`, `?v2`)
   - Define a `URI` constant with the version parameter
   - Implement `to_resource` class method that returns `MCP::Resource.new`
   - Implement `read` class method that returns the resource content
   - For HTML widgets, implement `meta` class method for OpenAI Apps SDK metadata

2. Register the resource in `app/controllers/mcp_controller.rb`:
   - Add `MyResource.to_resource` to the `resources:` array in `create_transport` method
   - Add a `when MyResource::URI` case in the `resources_read_handler` block

**IMPORTANT: Resource Versioning**

ChatGPT and other MCP clients cache resources aggressively. Always include a version parameter in your resource URI and increment it whenever you modify the resource content:

```ruby
class MyResource
  VERSION = "v1"  # Increment to v2, v3, etc. when content changes
  URI = "my-resource://data?#{VERSION}"
end
```

Without versioning, clients will continue using stale cached versions indefinitely, even after server restarts.

**Example resource structure:**
```ruby
class MyResource
  VERSION = "v1"
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

### Current Resources

- **LiveScoresWidgetResource** (`app/mcp_resources/live_scores_widget_resource.rb`): HTML widget for displaying live football scores in ChatGPT. Demonstrates OpenAI Apps SDK widget integration with `text/html+skybridge` mime type.

### Technology Stack

- Rails 8.0.2+ (was API-only, now full Rails for widget support)
- Ruby MCP SDK gem with StreamableHTTPTransport
- SQLite 3 with Solid adapters (solid_cache, solid_queue, solid_cable)
- Puma web server
- React 19 for interactive widgets
- ESBuild for JavaScript bundling (via jsbundling-rails)
- Propshaft for asset serving
- dotenv-rails for environment configuration

### React Widget Architecture

The application uses React for building interactive UI widgets that render inside ChatGPT's iframe:

**Structure:**
- `app/javascript/components/` - React components
- `app/javascript/application.js` - Entry point that mounts React
- `app/views/mcp_widgets/` - ERB templates that use Rails asset helpers
- `app/assets/builds/` - Built JavaScript bundles (served by Propshaft)
- `.env` - BASE_URL configuration (sets `config.asset_host` for full URLs)

**Asset Pipeline (Rails 8 Idiomatic):**
- **jsbundling-rails** - Manages JavaScript bundling with esbuild
- **Propshaft** - Modern asset pipeline that serves files from `app/assets/builds/`
- esbuild builds to `app/assets/builds/` (not `public/`)
- Propshaft adds digest fingerprinting in production (e.g., `application-abc123.js`)
- Views use `javascript_include_tag "application"` which generates full URLs via `config.asset_host`
- CORS headers applied automatically by rack-cors middleware

**Key Patterns:**
- Uses `useOpenAiGlobal()` hook with `useSyncExternalStore` to reactively subscribe to `window.openai` changes
- Listens for `openai:set_globals` events instead of polling
- Reads tool output from `window.openai.toolOutput`

**Development Workflow:**
1. Edit React components in `app/javascript/components/`
2. Run `npm run watch` to rebuild on changes (outputs to `app/assets/builds/`)
3. Increment resource `VERSION` constant to bust ChatGPT's cache
4. Test in ChatGPT (resource URI includes version, e.g., `ui://widget/live-scores.html?v18`)

### Adding New React Components

**1. Create a new React component in `app/javascript/components/`:**

```jsx
// app/javascript/components/ScoreCard.jsx
import React from 'react';

const ScoreCard = ({ match }) => {
  return (
    <div className="match">
      <div className="team-row">
        <span className="team-name">
          {match.possession === 'home' && <span className="possession">🏈</span>}
          {match.home_team}
        </span>
        <span className="team-score">{match.home_score}</span>
      </div>
      <div className="team-row">
        <span className="team-name">
          {match.possession === 'away' && <span className="possession">🏈</span>}
          {match.away_team}
        </span>
        <span className="team-score">{match.away_score}</span>
      </div>
      <div className="match-status">
        {match.quarter} - {match.time_remaining}
      </div>
    </div>
  );
};

export default ScoreCard;
```

**2. Use the OpenAI Apps SDK hooks to read tool data:**

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

**3. Register the component in `app/javascript/application.js`:**

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

**4. Create an ERB view template in `app/views/mcp_widgets/`:**

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

**5. Create a resource class in `app/mcp_resources/`:**

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
        template: "mcp_widgets/my_widget",
        layout: false
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

**6. Register the resource in `app/controllers/mcp_controller.rb`:**

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

**7. Rebuild assets and test:**

```bash
# Rebuild JavaScript
npm run build

# Increment VERSION in MyWidgetResource to v2, v3, etc. when making changes
# This forces ChatGPT to fetch the updated widget
```

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
