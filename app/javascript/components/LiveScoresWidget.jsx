import React, { useSyncExternalStore } from 'react';

// Custom hook to subscribe to window.openai global changes
// Based on OpenAI Apps SDK documentation pattern
const SET_GLOBALS_EVENT_TYPE = 'openai:set_globals';

function useOpenAiGlobal(key) {
  return useSyncExternalStore(
    (onChange) => {
      const handleSetGlobal = (event) => {
        const value = event.detail?.globals?.[key];
        if (value === undefined) {
          return;
        }
        onChange();
      };

      window.addEventListener(SET_GLOBALS_EVENT_TYPE, handleSetGlobal, {
        passive: true,
      });

      return () => {
        window.removeEventListener(SET_GLOBALS_EVENT_TYPE, handleSetGlobal);
      };
    },
    () => window.openai?.[key]
  );
}

// Convenience hooks for common tool data
function useToolOutput() {
  return useOpenAiGlobal('toolOutput');
}

const LiveScoresWidget = () => {
  // Use the reactive hook instead of polling
  const toolOutput = useToolOutput();

  const renderScores = () => {
    if (!toolOutput) {
      return <p>Waiting for data...</p>;
    }

    const matches = toolOutput.matches || [];
    const lastUpdated = toolOutput.lastUpdated;

    if (matches.length === 0) {
      return (
        <>
          <p>No live matches available</p>
          <details style={{ marginTop: '20px', fontSize: '12px', fontFamily: 'monospace' }}>
            <summary>Debug Info (click to expand)</summary>
            <pre style={{ background: '#f5f5f5', padding: '10px', overflow: 'auto', maxHeight: '300px' }}>
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
          <div style={{ textAlign: 'center', color: '#666', fontSize: '12px', marginBottom: '16px' }}>
            Last updated: {new Date(lastUpdated).toLocaleTimeString()}
          </div>
        )}
        {Object.entries(matchesByLeague).map(([league, leagueMatches]) => (
          <div key={league} className="league-section">
            <div className="league-title">{league}</div>
            {leagueMatches.map((match, idx) => (
              <div key={idx} className="match">
                <div className="team-row">
                  <span className="team-name">
                    {match.possession === 'home' && <span className="possession">🏈</span>}
                    {match.home_team}
                  </span>
                  <span className="team-score">{match.home_score}</span>
                </div>
                <div className="team-row">
                  <span className="team-name">
                    {match.possession === 'away' && <span className="possession">🏈</span>}
                    {match.away_team}
                  </span>
                  <span className="team-score">{match.away_score}</span>
                </div>
                <div className="match-status">
                  {match.quarter} - {match.time_remaining}
                </div>
              </div>
            ))}
          </div>
        ))}
      </>
    );
  };

  return (
    <div id="live-scores-root">
      <style>{`
        #live-scores-root {
          font-family: system-ui, -apple-system, sans-serif;
          padding: 20px;
        }
        .scores-container {
          max-width: 600px;
          margin: 0 auto;
        }
        .league-section {
          margin-bottom: 30px;
        }
        .league-title {
          font-size: 18px;
          font-weight: bold;
          margin-bottom: 12px;
          padding-bottom: 8px;
          border-bottom: 2px solid #333;
        }
        .match {
          background: #f5f5f5;
          border-radius: 8px;
          padding: 16px;
          margin-bottom: 12px;
        }
        .team-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin: 4px 0;
        }
        .team-name {
          font-weight: 500;
        }
        .team-score {
          font-weight: bold;
          font-size: 20px;
          min-width: 30px;
          text-align: right;
        }
        .possession {
          color: #059669;
          margin-right: 8px;
        }
        .match-status {
          text-align: center;
          color: #666;
          font-size: 14px;
          margin-top: 8px;
          padding-top: 8px;
          border-top: 1px solid #ddd;
        }
      `}</style>
      <div className="scores-container">
        <h2>🏟️ Live Football Scores</h2>
        <div id="scores-content">
          {renderScores()}
        </div>
      </div>
    </div>
  );
};

export default LiveScoresWidget;
