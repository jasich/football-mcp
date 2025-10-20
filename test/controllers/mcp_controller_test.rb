# frozen_string_literal: true

require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  test "should list resources without LiveScoresBoardResource" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 1,
        method: "resources/list"
      }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "2.0", json["jsonrpc"]
    assert_equal 1, json["id"]

    resources = json.dig("result", "resources")
    assert_not_nil resources, "Result should contain resources array"
    assert_equal 1, resources.length, "Should only have widget resource"

    # Should have the widget resource
    widget = resources.find { |r| r["uri"].start_with?("ui://widget/live-scores.html") }
    assert_not_nil widget, "Widget resource should be present"
    assert_equal "Live Scores Widget", widget["name"]
  end

  test "should read widget resource" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 2,
        method: "resources/read",
        params: {
          uri: LiveScoresWidgetResource::URI
        }
      }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "2.0", json["jsonrpc"]
    contents = json.dig("result", "contents")
    assert_not_nil contents, "Result should contain contents array"
    assert_equal 1, contents.length

    content = contents[0]
    assert_equal LiveScoresWidgetResource::URI, content["uri"]
    assert_equal "text/html+skybridge", content["mimeType"]
    assert_includes content["text"], "<div id=\"react-root\"", "Should contain React mount point"
    assert_includes content["text"], "data-component=\"LiveScoresWidget\"", "Should specify component name"
    assert_includes content["text"], "application", "Should include application.js script"
  end

  test "should return error for removed board resource" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 3,
        method: "resources/read",
        params: {
          uri: "live-scores://board"
        }
      }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json = JSON.parse(response.body)

    # Should return a JSON-RPC error for removed resource
    assert json["error"], "Should have error for removed resource"
    assert_equal -32603, json["error"]["code"], "Should return internal error code"
    assert json["error"]["message"], "Should have error message"
    # Verify there's no result when there's an error
    assert_nil json["result"], "Should not have result when there's an error"
  end
end
