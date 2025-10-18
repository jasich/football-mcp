# frozen_string_literal: true

class LiveScoresBoardResource
  URI = "live-scores://board"

  class << self
    def to_resource
      MCP::Resource.new(
        uri: URI,
        name: "Live Scores Board",
        description: "Real-time football scores board showing all live games",
        mime_type: "text/plain"
      )
    end

    def read
      scores = generate_mock_scores
      format_scores_board(scores)
    end

    private

    def generate_mock_scores
      [
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
    end

    def format_scores_board(matches)
      output = +""
      output << "LIVE FOOTBALL SCORES BOARD\n"
      output << "=" * 60 + "\n"
      output << "Updated: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\n"
      output << "=" * 60 + "\n\n"

      matches.group_by { |m| m[:league] }.each do |league, league_matches|
        output << "#{league}\n"
        output << "-" * 60 + "\n"

        league_matches.each do |match|
          home_indicator = match[:possession] == "home" ? "* " : "  "
          away_indicator = match[:possession] == "away" ? "* " : "  "

          output << sprintf(
            "%s%-30s %2d\n",
            home_indicator,
            match[:home_team],
            match[:home_score]
          )
          output << sprintf(
            "%s%-30s %2d    [%s %s]\n",
            away_indicator,
            match[:away_team],
            match[:away_score],
            match[:quarter],
            match[:time_remaining]
          )
          output << "\n"
        end

        output << "\n"
      end

      output << "* = Possession\n"
      output
    end
  end
end
