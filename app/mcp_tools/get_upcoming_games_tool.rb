# frozen_string_literal: true

class GetUpcomingGamesTool < MCP::Tool
  title "Get Upcoming Games"
  description "Lists the next scheduled games for a specific football team and includes ticket links."

  input_schema(
    type: "object",
    properties: {
      team_name: {
        type: "string",
        description: "Team name or nickname to look up"
      }
    },
    required: [ "team_name" ]
  )

  meta(
    "openai/outputTemplate" => UpcomingGamesWidgetResource::URI,
    "openai/toolInvocation/invoking" => "Gathering upcoming games",
    "openai/toolInvocation/invoked" => "Upcoming games displayed"
  )

  def self.call(team_name:, server_context: nil)
    schedule = find_schedule(team_name)

    if schedule.nil?
      return MCP::Tool::Response.new([ {
        "type" => "text",
        "text" => "Sorry, I couldn't find an upcoming schedule for '#{team_name}'. Try one of: #{available_teams.join(', ')}"
      } ])
    end

    MCP::Tool::Response.new(
      [ {
        "type" => "text",
        "text" => "Here are the next games for the #{schedule[:team_name]}."
      } ],
      structured_content: schedule
    )
  end

  class << self
    private

    def find_schedule(team_name)
      schedules.find do |entry|
        entry[:team_name].downcase.include?(team_name.downcase) ||
          entry[:short_name].downcase.include?(team_name.downcase)
      end
    end

    def available_teams
      schedules.map { |entry| entry[:team_name] }
    end

    def schedules
      @schedules ||= [
        {
          team_name: "Metro City Thunder",
          short_name: "Thunder",
          league: "Pro League",
          primary_color: "#3b82f6",
          upcoming_games: [
            {
              opponent: "West Coast Titans",
              date: "2025-10-27",
              kickoff: "7:15 PM ET",
              location: "Home",
              venue: "Metro City Stadium",
              theme: "Rivalry Night",
              starting_price: 145,
              tickets_url: "https://tickets.example.com/thunder-vs-titans"
            },
            {
              opponent: "Harbor Lions",
              date: "2025-11-03",
              kickoff: "4:05 PM ET",
              location: "Away",
              venue: "Bayfront Arena",
              theme: "Coastal Classic",
              starting_price: 98,
              tickets_url: "https://tickets.example.com/thunder-at-lions"
            },
            {
              opponent: "Central Stars",
              date: "2025-11-10",
              kickoff: "1:00 PM ET",
              location: "Home",
              venue: "Metro City Stadium",
              theme: "Salute to Service",
              starting_price: 120,
              tickets_url: "https://tickets.example.com/thunder-vs-stars"
            }
          ]
        },
        {
          team_name: "West Coast Titans",
          short_name: "Titans",
          league: "Pro League",
          primary_color: "#0ea5e9",
          upcoming_games: [
            {
              opponent: "Metro City Thunder",
              date: "2025-10-27",
              kickoff: "7:15 PM PT",
              location: "Away",
              venue: "Metro City Stadium",
              theme: "Prime Time Clash",
              starting_price: 132,
              tickets_url: "https://tickets.example.com/titans-at-thunder"
            },
            {
              opponent: "Northern Sentinels",
              date: "2025-11-02",
              kickoff: "5:25 PM PT",
              location: "Home",
              venue: "Pacific Field",
              theme: "Throwback Night",
              starting_price: 118,
              tickets_url: "https://tickets.example.com/titans-vs-sentinels"
            },
            {
              opponent: "Desert Comets",
              date: "2025-11-09",
              kickoff: "2:05 PM PT",
              location: "Home",
              venue: "Pacific Field",
              theme: "Legends Weekend",
              starting_price: 101,
              tickets_url: "https://tickets.example.com/titans-vs-comets"
            }
          ]
        },
        {
          team_name: "Northern Sentinels",
          short_name: "Sentinels",
          league: "Pro League",
          primary_color: "#2563eb",
          upcoming_games: [
            {
              opponent: "Harbor Lions",
              date: "2025-10-27",
              kickoff: "8:20 PM ET",
              location: "Home",
              venue: "Sentinel Bank Field",
              theme: "Division Showdown",
              starting_price: 109,
              tickets_url: "https://tickets.example.com/sentinels-vs-lions"
            },
            {
              opponent: "Metro City Thunder",
              date: "2025-11-02",
              kickoff: "1:00 PM ET",
              location: "Away",
              venue: "Metro City Stadium",
              theme: "Road Warriors",
              starting_price: 97,
              tickets_url: "https://tickets.example.com/sentinels-at-thunder"
            },
            {
              opponent: "Great Lakes Guardians",
              date: "2025-11-09",
              kickoff: "4:25 PM ET",
              location: "Home",
              venue: "Sentinel Bank Field",
              theme: "Family Weekend",
              starting_price: 89,
              tickets_url: "https://tickets.example.com/sentinels-vs-guardians"
            }
          ]
        },
        {
          team_name: "Southern University Wildcats",
          short_name: "Wildcats",
          league: "College League",
          primary_color: "#a855f7",
          upcoming_games: [
            {
              opponent: "Midland Pioneers",
              date: "2025-10-27",
              kickoff: "3:30 PM ET",
              location: "Home",
              venue: "Founders Field",
              theme: "Homecoming",
              starting_price: 75,
              tickets_url: "https://tickets.example.com/wildcats-vs-pioneers"
            },
            {
              opponent: "State Tech Warriors",
              date: "2025-11-02",
              kickoff: "7:00 PM ET",
              location: "Away",
              venue: "Warrior Coliseum",
              theme: "Conference Spotlight",
              starting_price: 64,
              tickets_url: "https://tickets.example.com/wildcats-at-warriors"
            },
            {
              opponent: "River City Falcons",
              date: "2025-11-09",
              kickoff: "6:00 PM ET",
              location: "Home",
              venue: "Founders Field",
              theme: "Senior Night",
              starting_price: 70,
              tickets_url: "https://tickets.example.com/wildcats-vs-falcons"
            }
          ]
        }
      ]
    end
  end
end
