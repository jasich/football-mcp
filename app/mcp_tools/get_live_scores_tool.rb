# frozen_string_literal: true

class GetLiveScoresTool < MCP::Tool
  title "Get Live Scores"
  description "Returns current live football scores"

  input_schema(
    type: "object",
    properties: {
      league: {
        type: "string",
        description: "Optional league filter (e.g., 'Pro League', 'College League')"
      }
    }
  )

  def self.call(league: nil, server_context: nil)
    scores = generate_mock_scores(league)

    MCP::Tool::Response.new([{
      "type" => "text",
      "text" => format_scores(scores)
    }])
  end

  private

  def self.generate_mock_scores(league_filter)
    all_matches = [
      {
        league: "Pro League",
        home_team: "Metro City Thunder",
        away_team: "Northern Sentinels",
        home_score: 24,
        away_score: 21,
        status: "LIVE",
        quarter: "Q3",
        time_remaining: "8:42",
        possession: "home"
      },
      {
        league: "Pro League",
        home_team: "West Coast Titans",
        away_team: "Central Stars",
        home_score: 17,
        away_score: 14,
        status: "LIVE",
        quarter: "Q2",
        time_remaining: "2:15",
        possession: "away"
      },
      {
        league: "Pro League",
        home_team: "East Side Hawks",
        away_team: "Harbor Lions",
        home_score: 31,
        away_score: 10,
        status: "LIVE",
        quarter: "Q4",
        time_remaining: "11:03",
        possession: "home"
      },
      {
        league: "College League",
        home_team: "Southern University Wildcats",
        away_team: "State Tech Warriors",
        home_score: 14,
        away_score: 21,
        status: "LIVE",
        quarter: "Q3",
        time_remaining: "5:30",
        possession: "away"
      },
      {
        league: "College League",
        home_team: "Midland Pioneers",
        away_team: "Riverside Rangers",
        home_score: 28,
        away_score: 28,
        status: "LIVE",
        quarter: "Q4",
        time_remaining: "0:58",
        possession: "home"
      }
    ]

    if league_filter && !league_filter.empty?
      all_matches.select { |m| m[:league].downcase.include?(league_filter.downcase) }
    else
      all_matches
    end
  end

  def self.format_scores(matches)
    return "No matches found" if matches.empty?

    output = +""
    output << "🏟️  LIVE FOOTBALL SCORES\n"
    output << "=" * 50 + "\n\n"

    matches.group_by { |m| m[:league] }.each do |league, league_matches|
      output << "#{league}\n"
      output << "-" * 50 + "\n"

      league_matches.each do |match|
        if match[:status] == "LIVE"
          home_display = match[:possession] == "home" ? "🏈 #{match[:home_team]}" : match[:home_team]
          away_display = match[:possession] == "away" ? "🏈 #{match[:away_team]}" : match[:away_team]
          status = "#{match[:quarter]} #{match[:time_remaining]}"
          output << "#{home_display} #{match[:home_score]} - #{away_display} #{match[:away_score]} [#{status}]\n"
        else
          output << "#{match[:home_team]} #{match[:home_score]} - #{match[:away_team]} #{match[:away_score]} [#{match[:status]}]\n"
        end
      end

      output << "\n"
    end

    output
  end
end
