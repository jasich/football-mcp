# frozen_string_literal: true

require "test_helper"

class GetLiveScoresToolTest < ActiveSupport::TestCase
  test "returns all matches when no league filter is provided" do
    response = GetLiveScoresTool.call

    assert_instance_of MCP::Tool::Response, response
    assert_equal 1, response.content.length
    assert_equal "text", response.content[0]["type"]
    assert_includes response.content[0]["text"], "live football scores"

    # Check structured content
    assert_not_nil response.structured_content
    assert_not_nil response.structured_content[:matches]
    assert_not_nil response.structured_content[:lastUpdated]
    assert_equal 5, response.structured_content[:matches].length
  end

  test "filters matches by league when league parameter is provided" do
    response = GetLiveScoresTool.call(league: "Pro League")

    matches = response.structured_content[:matches]
    assert_equal 3, matches.length
    matches.each do |match|
      assert_equal "Pro League", match[:league]
    end
  end

  test "filters matches by college league" do
    response = GetLiveScoresTool.call(league: "College League")

    matches = response.structured_content[:matches]
    assert_equal 2, matches.length
    matches.each do |match|
      assert_equal "College League", match[:league]
    end
  end

  test "league filter is case insensitive" do
    response = GetLiveScoresTool.call(league: "pro league")

    matches = response.structured_content[:matches]
    assert_equal 3, matches.length
  end

  test "returns empty array when league filter matches no leagues" do
    response = GetLiveScoresTool.call(league: "Nonexistent League")

    matches = response.structured_content[:matches]
    assert_equal 0, matches.length
  end

  test "all matches have required fields" do
    response = GetLiveScoresTool.call

    matches = response.structured_content[:matches]
    matches.each do |match|
      assert_not_nil match[:league]
      assert_not_nil match[:home_team]
      assert_not_nil match[:away_team]
      assert_not_nil match[:home_score]
      assert_not_nil match[:away_score]
      assert_not_nil match[:status]
      assert_not_nil match[:quarter]
      assert_not_nil match[:time_remaining]
      assert_not_nil match[:possession]
      assert_includes [ "home", "away" ], match[:possession]
    end
  end

  test "lastUpdated timestamp is in ISO8601 format" do
    response = GetLiveScoresTool.call

    last_updated = response.structured_content[:lastUpdated]
    assert_not_nil last_updated

    # Verify it can be parsed as a valid ISO8601 timestamp
    parsed_time = Time.iso8601(last_updated)
    assert_instance_of Time, parsed_time
  end

  test "has correct metadata for ChatGPT integration" do
    metadata = GetLiveScoresTool.meta

    assert_equal LiveScoresWidgetResource::URI, metadata["openai/outputTemplate"]
    assert_equal "Loading live scores", metadata["openai/toolInvocation/invoking"]
    assert_equal "Live scores displayed", metadata["openai/toolInvocation/invoked"]
  end

  test "accepts server_context parameter without error" do
    response = GetLiveScoresTool.call(league: "Pro League", server_context: { some: "context" })

    assert_instance_of MCP::Tool::Response, response
  end
end
