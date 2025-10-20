# frozen_string_literal: true

require "test_helper"

class GetTeamInfoToolTest < ActiveSupport::TestCase
  test "returns team info when team name matches" do
    response = GetTeamInfoTool.call(team_name: "Metro City Thunder")

    assert_instance_of MCP::Tool::Response, response
    assert_equal 1, response.content.length
    assert_includes response.content[0]["text"], "Metro City Thunder"

    # Check structured content
    team_data = response.structured_content
    assert_equal "Metro City Thunder", team_data[:name]
    assert_equal "Thunder", team_data[:short_name]
    assert_equal "Pro League", team_data[:league]
  end

  test "finds team by short name" do
    response = GetTeamInfoTool.call(team_name: "Thunder")

    team_data = response.structured_content
    assert_equal "Metro City Thunder", team_data[:name]
  end

  test "search is case insensitive" do
    response = GetTeamInfoTool.call(team_name: "metro city thunder")

    team_data = response.structured_content
    assert_equal "Metro City Thunder", team_data[:name]
  end

  test "finds team by partial name match" do
    response = GetTeamInfoTool.call(team_name: "Wildcats")

    team_data = response.structured_content
    assert_equal "Southern University Wildcats", team_data[:name]
  end

  test "returns error message when team is not found" do
    response = GetTeamInfoTool.call(team_name: "Nonexistent Team")

    assert_equal 1, response.content.length
    assert_includes response.content[0]["text"], "couldn't find information"
    assert_includes response.content[0]["text"], "Nonexistent Team"
    assert_nil response.structured_content
  end

  test "error message lists available teams" do
    response = GetTeamInfoTool.call(team_name: "Unknown")

    assert_includes response.content[0]["text"], "Metro City Thunder"
    assert_includes response.content[0]["text"], "Northern Sentinels"
  end

  test "team data includes all required fields" do
    response = GetTeamInfoTool.call(team_name: "Thunder")

    team_data = response.structured_content
    assert_not_nil team_data[:name]
    assert_not_nil team_data[:short_name]
    assert_not_nil team_data[:league]
    assert_not_nil team_data[:conference]
    assert_not_nil team_data[:division]
    assert_not_nil team_data[:logo]
    assert_not_nil team_data[:record]
    assert_not_nil team_data[:stats]
    assert_not_nil team_data[:recent_games]
    assert_not_nil team_data[:key_players]
    assert_not_nil team_data[:next_game]
  end

  test "record has wins, losses, and ties" do
    response = GetTeamInfoTool.call(team_name: "Thunder")

    record = response.structured_content[:record]
    assert_not_nil record[:wins]
    assert_not_nil record[:losses]
    assert_not_nil record[:ties]
    assert record[:wins] >= 0
    assert record[:losses] >= 0
    assert record[:ties] >= 0
  end

  test "stats include all performance metrics" do
    response = GetTeamInfoTool.call(team_name: "Thunder")

    stats = response.structured_content[:stats]
    assert_not_nil stats[:points_per_game]
    assert_not_nil stats[:points_allowed]
    assert_not_nil stats[:total_yards_per_game]
    assert_not_nil stats[:passing_yards_per_game]
    assert_not_nil stats[:rushing_yards_per_game]
  end

  test "recent games is an array with game data" do
    response = GetTeamInfoTool.call(team_name: "Thunder")

    recent_games = response.structured_content[:recent_games]
    assert_instance_of Array, recent_games
    assert recent_games.length > 0

    recent_games.each do |game|
      assert_not_nil game[:opponent]
      assert_not_nil game[:result]
      assert_not_nil game[:score]
      assert_not_nil game[:date]
      assert_includes [ "W", "L", "T" ], game[:result]
    end
  end

  test "key players is an array with player data" do
    response = GetTeamInfoTool.call(team_name: "Thunder")

    key_players = response.structured_content[:key_players]
    assert_instance_of Array, key_players
    assert key_players.length > 0

    key_players.each do |player|
      assert_not_nil player[:name]
      assert_not_nil player[:position]
      assert_not_nil player[:number]
      assert_not_nil player[:stats]
    end
  end

  test "next game includes opponent, date, and location" do
    response = GetTeamInfoTool.call(team_name: "Thunder")

    next_game = response.structured_content[:next_game]
    assert_not_nil next_game[:opponent]
    assert_not_nil next_game[:date]
    assert_not_nil next_game[:location]
    assert_includes [ "Home", "Away" ], next_game[:location]
  end

  test "has correct metadata for ChatGPT integration" do
    metadata = GetTeamInfoTool.meta

    assert_equal TeamInfoWidgetResource::URI, metadata["openai/outputTemplate"]
    assert_equal "Loading team information", metadata["openai/toolInvocation/invoking"]
    assert_equal "Team information displayed", metadata["openai/toolInvocation/invoked"]
  end

  test "accepts server_context parameter without error" do
    response = GetTeamInfoTool.call(team_name: "Thunder", server_context: { some: "context" })

    assert_instance_of MCP::Tool::Response, response
  end

  test "all teams in dataset can be found" do
    # Test that we can retrieve each team
    teams = [ "Metro City Thunder", "Northern Sentinels", "West Coast Titans", "Southern University Wildcats" ]

    teams.each do |team_name|
      response = GetTeamInfoTool.call(team_name: team_name)
      assert_not_nil response.structured_content, "Should find team: #{team_name}"
      assert_equal team_name, response.structured_content[:name]
    end
  end
end
