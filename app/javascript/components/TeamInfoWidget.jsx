import React from 'react';
import { useToolOutput } from '../utils/openai-hooks';

const TeamInfoWidget = () => {
  const toolOutput = useToolOutput();

  const renderTeamInfo = () => {
    if (!toolOutput) {
      return <p className="text-gray-700 dark:text-gray-300">Waiting for team data...</p>;
    }

    const {
      name,
      short_name,
      league,
      conference,
      division,
      logo,
      record,
      stats,
      recent_games,
      key_players,
      next_game
    } = toolOutput;

    return (
      <>
        {/* Team Header */}
        <div className="flex items-center gap-5 mb-8 p-5 bg-gradient-to-br from-indigo-500 to-purple-600 dark:from-indigo-600 dark:to-purple-700 rounded-xl text-white">
          <div className="text-6xl leading-none">{logo}</div>
          <div className="flex-1">
            <h2 className="m-0 mb-2 text-[28px] font-bold">{name}</h2>
            <div className="text-sm opacity-90 mb-1">
              {league} • {conference} Conference • {division} Division
            </div>
            <div className="text-lg font-semibold mt-2">
              Record: {record.wins}-{record.losses}{record.ties > 0 && `-${record.ties}`}
            </div>
          </div>
        </div>

        {/* Stats Section */}
        <div className="mb-6 bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
          <h3 className="m-0 mb-4 text-lg font-semibold">Season Stats</h3>
          <div className="grid grid-cols-[repeat(auto-fit,minmax(140px,1fr))] gap-3">
            <div className="bg-white dark:bg-gray-700 p-3 rounded-md text-center">
              <div className="text-xs text-gray-500 dark:text-gray-400 mb-1">Points Per Game</div>
              <div className="text-xl font-bold">{stats.points_per_game}</div>
            </div>
            <div className="bg-white dark:bg-gray-700 p-3 rounded-md text-center">
              <div className="text-xs text-gray-500 dark:text-gray-400 mb-1">Points Allowed</div>
              <div className="text-xl font-bold">{stats.points_allowed}</div>
            </div>
            <div className="bg-white dark:bg-gray-700 p-3 rounded-md text-center">
              <div className="text-xs text-gray-500 dark:text-gray-400 mb-1">Total Yards/Game</div>
              <div className="text-xl font-bold">{stats.total_yards_per_game}</div>
            </div>
            <div className="bg-white dark:bg-gray-700 p-3 rounded-md text-center">
              <div className="text-xs text-gray-500 dark:text-gray-400 mb-1">Passing Yards/Game</div>
              <div className="text-xl font-bold">{stats.passing_yards_per_game}</div>
            </div>
            <div className="bg-white dark:bg-gray-700 p-3 rounded-md text-center">
              <div className="text-xs text-gray-500 dark:text-gray-400 mb-1">Rushing Yards/Game</div>
              <div className="text-xl font-bold">{stats.rushing_yards_per_game}</div>
            </div>
          </div>
        </div>

        {/* Recent Games */}
        <div className="mb-6 bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
          <h3 className="m-0 mb-4 text-lg font-semibold">Recent Games</h3>
          <div className="flex flex-col gap-2">
            {recent_games.map((game, idx) => (
              <div key={idx} className={`flex items-center gap-3 bg-white dark:bg-gray-700 p-3 rounded-md ${game.result === 'W' ? 'border-l-4 border-l-emerald-500' : 'border-l-4 border-l-red-500'}`}>
                <div className={`font-bold text-lg w-6 ${game.result === 'W' ? 'text-emerald-500' : 'text-red-500'}`}>{game.result}</div>
                <div className="flex-1">
                  <div className="font-medium">vs {game.opponent}</div>
                  <div className="text-sm text-gray-500 dark:text-gray-400">{game.score}</div>
                </div>
                <div className="text-xs text-gray-400 dark:text-gray-500">{new Date(game.date).toLocaleDateString()}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Key Players */}
        <div className="mb-6 bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
          <h3 className="m-0 mb-4 text-lg font-semibold">Key Players</h3>
          <div className="flex flex-col gap-2">
            {key_players.map((player, idx) => (
              <div key={idx} className="bg-white dark:bg-gray-700 p-3 rounded-md">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-bold text-gray-500 dark:text-gray-400 min-w-[32px]">#{player.number}</span>
                  <span className="font-semibold flex-1">{player.name}</span>
                  <span className="bg-gray-200 dark:bg-gray-600 px-2 py-0.5 rounded text-xs font-semibold text-gray-600 dark:text-gray-300">{player.position}</span>
                </div>
                <div className="text-[13px] text-gray-500 dark:text-gray-400 ml-10">{player.stats}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Next Game */}
        {next_game && (
          <div className="mb-6 bg-amber-100 dark:bg-amber-900 rounded-lg p-4 border-2 border-amber-400 dark:border-amber-600">
            <h3 className="m-0 mb-4 text-lg font-semibold text-amber-900 dark:text-amber-100">Next Game</h3>
            <div className="text-center">
              <div className="text-xl font-bold mb-2 text-amber-900 dark:text-amber-100">vs {next_game.opponent}</div>
              <div className="text-sm text-amber-800 dark:text-amber-200">
                {new Date(next_game.date).toLocaleDateString()} • {next_game.location}
              </div>
            </div>
          </div>
        )}
      </>
    );
  };

  return (
    <div className="font-sans p-5 max-w-[700px] mx-auto bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100 min-h-screen">
      {renderTeamInfo()}
    </div>
  );
};

export default TeamInfoWidget;
