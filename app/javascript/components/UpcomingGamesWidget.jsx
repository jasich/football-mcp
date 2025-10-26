import React, { useState } from 'react';
import { useToolOutput } from '../utils/openai-hooks';

const UpcomingGamesWidget = () => {
  const toolOutput = useToolOutput();
  const [recentSelection, setRecentSelection] = useState(null);

  if (!toolOutput) {
    return <p className="p-5 bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100 min-h-screen">Loading upcoming games...</p>;
  }

  const {
    team_name: teamName,
    league,
    primary_color: primaryColor,
    upcoming_games: upcomingGames = []
  } = toolOutput;

  const handleBuyTickets = (game) => {
    setRecentSelection({
      opponent: game.opponent,
      date: game.date
    });

    if (game.tickets_url) {
      window.open(game.tickets_url, '_blank', 'noopener');
    }
  };

  return (
    <div className="font-sans p-5 bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100 min-h-screen">
      <div className="max-w-[680px] mx-auto">
        <div
          className="bg-gray-50 dark:bg-gray-800 p-4 rounded-[10px] mb-6"
          style={{ borderLeft: `6px solid ${primaryColor || '#111827'}` }}
        >
          <h2 className="m-0 text-[26px] font-bold">{teamName}</h2>
          <div className="text-gray-500 dark:text-gray-400 text-sm mt-1">
            Upcoming schedule • {league}
          </div>
        </div>

        {upcomingGames.length === 0 ? (
          <p className="text-gray-700 dark:text-gray-300">No upcoming games found.</p>
        ) : (
          upcomingGames.map((game, index) => (
            <div key={`${game.opponent}-${game.date}-${index}`} className="bg-white dark:bg-gray-800 rounded-[10px] p-4 mb-4 shadow-sm border border-gray-200 dark:border-gray-700">
              <div className="text-lg font-semibold">vs {game.opponent}</div>
              <div className="flex flex-wrap gap-3 text-sm text-gray-600 dark:text-gray-400 my-2">
                <span>{new Date(game.date).toLocaleDateString()}</span>
                <span>{game.kickoff}</span>
                <span>{game.location} • {game.venue}</span>
                <span>{game.theme}</span>
              </div>
              <div className="flex justify-between items-center gap-3 flex-wrap">
                <div>
                  <strong>Tickets from</strong> <span>${game.starting_price || '89'}</span>
                </div>
                <button
                  type="button"
                  className="text-white border-0 rounded-full px-5 py-2.5 text-sm font-semibold cursor-pointer inline-flex items-center gap-1.5 transition-all duration-150 hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow-none"
                  style={{ background: primaryColor || '#2563eb' }}
                  onClick={() => handleBuyTickets(game)}
                >
                  🎟️ Buy Tickets
                </button>
              </div>
            </div>
          ))
        )}

        {recentSelection && (
          <div className="mt-4 text-[13px] text-gray-700 dark:text-gray-300 bg-lime-100 dark:bg-lime-900 border border-lime-300 dark:border-lime-700 rounded-lg py-2.5 px-3.5">
            Opening ticket info for {recentSelection.opponent} on {new Date(recentSelection.date).toLocaleDateString()}...
          </div>
        )}
      </div>
    </div>
  );
};

export default UpcomingGamesWidget;
