Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # MCP server endpoints
  # POST: JSON-RPC requests (initialize, tools/list, tools/call, etc.)
  # GET: SSE stream connections (requires Mcp-Session-Id header)
  # DELETE: Session cleanup (requires Mcp-Session-Id header)
  post "mcp" => "mcp#handle"
  get "mcp" => "mcp#handle"
  delete "mcp" => "mcp#handle"

  # Defines the root path route ("/")
  # root "posts#index"
end
