import React from 'react';
import { useToolOutput } from '../utils/openai-hooks';

const LiveScoresWidget = () => {
  // Use the reactive hook instead of polling
  const toolOutput = useToolOutput();

  const handleShowUpcoming = async (teamName) => {
    await window.openai?.sendFollowUpMessage({
      prompt: `Show upcoming games for the ${teamName}.`
    });
  };

  const renderScores = () => {
    if (!toolOutput) {
      return <p>Waiting for data...</p>;
    }

    const matches = toolOutput.matches || [];
    const lastUpdated = toolOutput.lastUpdated;

    if (matches.length === 0) {
      return (
        <>
          <p className="text-gray-700 dark:text-gray-300">No live matches available</p>
          <details className="mt-5 text-xs font-mono">
            <summary className="cursor-pointer text-gray-700 dark:text-gray-300">Debug Info (click to expand)</summary>
            <pre className="bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100 p-2.5 overflow-auto max-h-[300px] mt-2">
              {JSON.stringify(toolOutput, null, 2)}
            </pre>
          </details>
        </>
      );
    }

    // Group matches by league
    const matchesByLeague = {};
    matches.forEach(match => {
      if (!matchesByLeague[match.league]) {
        matchesByLeague[match.league] = [];
      }
      matchesByLeague[match.league].push(match);
    });

    return (
      <>
        {lastUpdated && (
          <div className="text-center text-gray-600 dark:text-gray-400 text-xs mb-4">
            Last updated: {new Date(lastUpdated).toLocaleTimeString()}
          </div>
        )}
        {Object.entries(matchesByLeague).map(([league, leagueMatches]) => (
          <div key={league} className="mb-8">
            <div className="text-lg font-bold mb-3 pb-2 border-b-2 border-gray-800 dark:border-gray-200">{league}</div>
            {leagueMatches.map((match, idx) => (
              <div key={idx} className="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 mb-3">
                <div className="flex justify-between items-center my-1">
                  <span className="font-medium">
                    {match.possession === 'home' && <span className="text-emerald-600 dark:text-emerald-400 mr-2">🏈</span>}
                    {match.home_team}
                  </span>
                  <span className="font-bold text-xl min-w-[30px] text-right">{match.home_score}</span>
                </div>
                <div className="flex justify-between items-center my-1">
                  <span className="font-medium">
                    {match.possession === 'away' && <span className="text-emerald-600 dark:text-emerald-400 mr-2">🏈</span>}
                    {match.away_team}
                  </span>
                  <span className="font-bold text-xl min-w-[30px] text-right">{match.away_score}</span>
                </div>
                <div className="text-center text-gray-600 dark:text-gray-400 text-sm mt-2 pt-2 border-t border-gray-300 dark:border-gray-600">
                  {match.quarter} - {match.time_remaining}
                </div>
                <div className="flex flex-wrap gap-2.5 mt-3">
                  <button
                    type="button"
                    className="flex-1 min-w-[200px] bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 border-0 rounded-md px-3.5 py-2.5 text-sm font-semibold cursor-pointer transition-all duration-150 hover:-translate-y-0.5 hover:shadow-md disabled:bg-gray-400 disabled:dark:bg-gray-600 disabled:cursor-not-allowed disabled:shadow-none"
                    onClick={() => handleShowUpcoming(match.home_team)}
                  >
                    Show {match.home_team} games →
                  </button>
                  <button
                    type="button"
                    className="flex-1 min-w-[200px] bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 border-0 rounded-md px-3.5 py-2.5 text-sm font-semibold cursor-pointer transition-all duration-150 hover:-translate-y-0.5 hover:shadow-md disabled:bg-gray-400 disabled:dark:bg-gray-600 disabled:cursor-not-allowed disabled:shadow-none"
                    onClick={() => handleShowUpcoming(match.away_team)}
                  >
                    Show {match.away_team} games →
                  </button>
                </div>
              </div>
            ))}
          </div>
        ))}
      </>
    );
  };

  return (
    <div className="font-sans p-5 bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100 min-h-screen">
      <div className="max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-4">🏟️ Live Football Scores</h2>
        <div id="scores-content">
          {renderScores()}
        </div>
      </div>
    </div>
  );
};

export default LiveScoresWidget;
