# frozen_string_literal: true

require "test_helper"

class GetUpcomingGamesToolTest < ActiveSupport::TestCase
  test "returns schedule when team name matches" do
    response = GetUpcomingGamesTool.call(team_name: "Metro City Thunder")

    assert_instance_of MCP::Tool::Response, response
    assert_equal 1, response.content.length
    assert_includes response.content[0]["text"], "Metro City Thunder"

    # Check structured content
    schedule = response.structured_content
    assert_equal "Metro City Thunder", schedule[:team_name]
    assert_equal "Thunder", schedule[:short_name]
    assert_equal "Pro League", schedule[:league]
  end

  test "finds team by short name" do
    response = GetUpcomingGamesTool.call(team_name: "Thunder")

    schedule = response.structured_content
    assert_equal "Metro City Thunder", schedule[:team_name]
  end

  test "search is case insensitive" do
    response = GetUpcomingGamesTool.call(team_name: "metro city thunder")

    schedule = response.structured_content
    assert_equal "Metro City Thunder", schedule[:team_name]
  end

  test "finds team by partial name match" do
    response = GetUpcomingGamesTool.call(team_name: "Titans")

    schedule = response.structured_content
    assert_equal "West Coast Titans", schedule[:team_name]
  end

  test "returns error message when team is not found" do
    response = GetUpcomingGamesTool.call(team_name: "Nonexistent Team")

    assert_equal 1, response.content.length
    assert_includes response.content[0]["text"], "couldn't find an upcoming schedule"
    assert_includes response.content[0]["text"], "Nonexistent Team"
    assert_nil response.structured_content
  end

  test "error message lists available teams" do
    response = GetUpcomingGamesTool.call(team_name: "Unknown")

    assert_includes response.content[0]["text"], "Metro City Thunder"
    assert_includes response.content[0]["text"], "Northern Sentinels"
  end

  test "schedule includes all required fields" do
    response = GetUpcomingGamesTool.call(team_name: "Thunder")

    schedule = response.structured_content
    assert_not_nil schedule[:team_name]
    assert_not_nil schedule[:short_name]
    assert_not_nil schedule[:league]
    assert_not_nil schedule[:primary_color]
    assert_not_nil schedule[:upcoming_games]
  end

  test "primary color is valid hex format" do
    response = GetUpcomingGamesTool.call(team_name: "Thunder")

    primary_color = response.structured_content[:primary_color]
    assert_match(/^#[0-9a-f]{6}$/i, primary_color, "Primary color should be valid hex format")
  end

  test "upcoming games is an array with game data" do
    response = GetUpcomingGamesTool.call(team_name: "Thunder")

    upcoming_games = response.structured_content[:upcoming_games]
    assert_instance_of Array, upcoming_games
    assert upcoming_games.length > 0
  end

  test "each game includes all required fields" do
    response = GetUpcomingGamesTool.call(team_name: "Thunder")

    upcoming_games = response.structured_content[:upcoming_games]
    upcoming_games.each do |game|
      assert_not_nil game[:opponent]
      assert_not_nil game[:date]
      assert_not_nil game[:kickoff]
      assert_not_nil game[:location]
      assert_not_nil game[:venue]
      assert_not_nil game[:theme]
      assert_not_nil game[:starting_price]
      assert_not_nil game[:tickets_url]

      # Validate data types and formats
      assert_includes [ "Home", "Away" ], game[:location]
      assert game[:starting_price].is_a?(Integer), "Starting price should be an integer"
      assert game[:starting_price] > 0, "Starting price should be positive"
      assert_match(/^https:\/\//, game[:tickets_url], "Ticket URL should be HTTPS")
    end
  end

  test "game dates are in valid format" do
    response = GetUpcomingGamesTool.call(team_name: "Thunder")

    upcoming_games = response.structured_content[:upcoming_games]
    upcoming_games.each do |game|
      # Should be able to parse as a valid date
      assert_nothing_raised do
        Date.parse(game[:date])
      end
    end
  end

  test "has correct metadata for ChatGPT integration" do
    metadata = GetUpcomingGamesTool.meta

    assert_equal UpcomingGamesWidgetResource::URI, metadata["openai/outputTemplate"]
    assert_equal "Gathering upcoming games", metadata["openai/toolInvocation/invoking"]
    assert_equal "Upcoming games displayed", metadata["openai/toolInvocation/invoked"]
  end

  test "accepts server_context parameter without error" do
    response = GetUpcomingGamesTool.call(team_name: "Thunder", server_context: { some: "context" })

    assert_instance_of MCP::Tool::Response, response
  end

  test "all teams in dataset can be found" do
    # Test that we can retrieve each team's schedule
    teams = [ "Metro City Thunder", "West Coast Titans", "Northern Sentinels", "Southern University Wildcats" ]

    teams.each do |team_name|
      response = GetUpcomingGamesTool.call(team_name: team_name)
      assert_not_nil response.structured_content, "Should find schedule for: #{team_name}"
      assert_equal team_name, response.structured_content[:team_name]
    end
  end

  test "each team has multiple upcoming games" do
    teams = [ "Metro City Thunder", "West Coast Titans", "Northern Sentinels", "Southern University Wildcats" ]

    teams.each do |team_name|
      response = GetUpcomingGamesTool.call(team_name: team_name)
      upcoming_games = response.structured_content[:upcoming_games]
      assert upcoming_games.length >= 3, "#{team_name} should have at least 3 upcoming games"
    end
  end
end
