# frozen_string_literal: true

class GetTeamInfoTool < MCP::Tool
  title "Get Team Info"
  description "Returns detailed information about a specific football team including stats, roster, and recent games."

  input_schema(
    type: "object",
    properties: {
      team_name: {
        type: "string",
        description: "The name of the team to get information about"
      }
    },
    required: [ "team_name" ]
  )

  meta(
    "openai/outputTemplate" => TeamInfoWidgetResource::URI,
    "openai/toolInvocation/invoking" => "Loading team information",
    "openai/toolInvocation/invoked" => "Team information displayed"
  )

  def self.call(team_name:, server_context: nil)
    team_data = find_team_data(team_name)

    if team_data.nil?
      return MCP::Tool::Response.new([ {
        "type" => "text",
        "text" => "Sorry, I couldn't find information for '#{team_name}'. Available teams: #{available_teams.join(', ')}"
      } ])
    end

    response = MCP::Tool::Response.new(
      [ {
        "type" => "text",
        "text" => "Here's detailed information about the #{team_data[:name]}."
      } ],
      structured_content: team_data
    )

    response
  end

  private

  def self.find_team_data(team_name)
    all_teams.find do |team|
      team[:name].downcase.include?(team_name.downcase) ||
        team[:short_name].downcase.include?(team_name.downcase)
    end
  end

  def self.available_teams
    all_teams.map { |t| t[:name] }
  end

  def self.all_teams
    [
      {
        name: "Metro City Thunder",
        short_name: "Thunder",
        league: "Pro League",
        conference: "Eastern",
        division: "North",
        logo: "⚡",
        record: { wins: 8, losses: 3, ties: 0 },
        stats: {
          points_per_game: 27.4,
          points_allowed: 21.2,
          total_yards_per_game: 385.6,
          passing_yards_per_game: 265.3,
          rushing_yards_per_game: 120.3
        },
        recent_games: [
          { opponent: "Northern Sentinels", result: "W", score: "24-21", date: "2025-10-13" },
          { opponent: "Harbor Lions", result: "W", score: "31-17", date: "2025-10-06" },
          { opponent: "Central Stars", result: "L", score: "20-23", date: "2025-09-29" }
        ],
        key_players: [
          { name: "Marcus Johnson", position: "QB", number: 12, stats: "2,847 yards, 22 TDs" },
          { name: "David Williams", position: "RB", number: 28, stats: "892 yards, 8 TDs" },
          { name: "James Carter", position: "WR", number: 84, stats: "67 rec, 1,124 yards, 9 TDs" }
        ],
        next_game: {
          opponent: "West Coast Titans",
          date: "2025-10-27",
          location: "Home"
        }
      },
      {
        name: "Northern Sentinels",
        short_name: "Sentinels",
        league: "Pro League",
        conference: "Eastern",
        division: "North",
        logo: "🛡️",
        record: { wins: 6, losses: 5, ties: 0 },
        stats: {
          points_per_game: 23.8,
          points_allowed: 24.1,
          total_yards_per_game: 348.2,
          passing_yards_per_game: 242.8,
          rushing_yards_per_game: 105.4
        },
        recent_games: [
          { opponent: "Metro City Thunder", result: "L", score: "21-24", date: "2025-10-13" },
          { opponent: "East Side Hawks", result: "W", score: "27-20", date: "2025-10-06" },
          { opponent: "West Coast Titans", result: "L", score: "17-21", date: "2025-09-29" }
        ],
        key_players: [
          { name: "Tyler Anderson", position: "QB", number: 7, stats: "2,456 yards, 18 TDs" },
          { name: "Chris Thompson", position: "RB", number: 22, stats: "743 yards, 6 TDs" },
          { name: "Michael Davis", position: "WR", number: 19, stats: "59 rec, 892 yards, 7 TDs" }
        ],
        next_game: {
          opponent: "Harbor Lions",
          date: "2025-10-27",
          location: "Away"
        }
      },
      {
        name: "West Coast Titans",
        short_name: "Titans",
        league: "Pro League",
        conference: "Western",
        division: "Pacific",
        logo: "🌊",
        record: { wins: 9, losses: 2, ties: 0 },
        stats: {
          points_per_game: 29.1,
          points_allowed: 19.8,
          total_yards_per_game: 402.3,
          passing_yards_per_game: 285.7,
          rushing_yards_per_game: 116.6
        },
        recent_games: [
          { opponent: "Central Stars", result: "W", score: "17-14", date: "2025-10-13" },
          { opponent: "East Side Hawks", result: "W", score: "35-28", date: "2025-10-06" },
          { opponent: "Northern Sentinels", result: "W", score: "21-17", date: "2025-09-29" }
        ],
        key_players: [
          { name: "Aaron Mitchell", position: "QB", number: 9, stats: "3,142 yards, 26 TDs" },
          { name: "Brandon Lee", position: "RB", number: 31, stats: "1,021 yards, 11 TDs" },
          { name: "Robert Garcia", position: "WR", number: 88, stats: "73 rec, 1,287 yards, 12 TDs" }
        ],
        next_game: {
          opponent: "Metro City Thunder",
          date: "2025-10-27",
          location: "Away"
        }
      },
      {
        name: "Southern University Wildcats",
        short_name: "Wildcats",
        league: "College League",
        conference: "ACC",
        division: "Atlantic",
        logo: "🐱",
        record: { wins: 5, losses: 4, ties: 0 },
        stats: {
          points_per_game: 24.2,
          points_allowed: 22.8,
          total_yards_per_game: 362.5,
          passing_yards_per_game: 251.3,
          rushing_yards_per_game: 111.2
        },
        recent_games: [
          { opponent: "State Tech Warriors", result: "L", score: "14-21", date: "2025-10-13" },
          { opponent: "Riverside Rangers", result: "W", score: "31-24", date: "2025-10-06" },
          { opponent: "Midland Pioneers", result: "W", score: "28-17", date: "2025-09-29" }
        ],
        key_players: [
          { name: "Jake Wilson", position: "QB", number: 14, stats: "2,263 yards, 17 TDs" },
          { name: "Kevin Brown", position: "RB", number: 24, stats: "834 yards, 9 TDs" },
          { name: "Ryan Martinez", position: "WR", number: 3, stats: "52 rec, 978 yards, 8 TDs" }
        ],
        next_game: {
          opponent: "Midland Pioneers",
          date: "2025-10-27",
          location: "Home"
        }
      }
    ]
  end
end
