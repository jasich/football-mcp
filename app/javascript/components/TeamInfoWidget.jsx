import React, { useSyncExternalStore } from 'react';

// Custom hook to subscribe to window.openai global changes
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

function useToolOutput() {
  return useOpenAiGlobal('toolOutput');
}

const TeamInfoWidget = () => {
  const toolOutput = useToolOutput();

  const renderTeamInfo = () => {
    if (!toolOutput) {
      return <p>Waiting for team data...</p>;
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
        <div className="team-header">
          <div className="team-logo">{logo}</div>
          <div className="team-header-info">
            <h2 className="team-name">{name}</h2>
            <div className="team-meta">
              {league} • {conference} Conference • {division} Division
            </div>
            <div className="team-record">
              Record: {record.wins}-{record.losses}{record.ties > 0 && `-${record.ties}`}
            </div>
          </div>
        </div>

        {/* Stats Section */}
        <div className="section">
          <h3 className="section-title">Season Stats</h3>
          <div className="stats-grid">
            <div className="stat-item">
              <div className="stat-label">Points Per Game</div>
              <div className="stat-value">{stats.points_per_game}</div>
            </div>
            <div className="stat-item">
              <div className="stat-label">Points Allowed</div>
              <div className="stat-value">{stats.points_allowed}</div>
            </div>
            <div className="stat-item">
              <div className="stat-label">Total Yards/Game</div>
              <div className="stat-value">{stats.total_yards_per_game}</div>
            </div>
            <div className="stat-item">
              <div className="stat-label">Passing Yards/Game</div>
              <div className="stat-value">{stats.passing_yards_per_game}</div>
            </div>
            <div className="stat-item">
              <div className="stat-label">Rushing Yards/Game</div>
              <div className="stat-value">{stats.rushing_yards_per_game}</div>
            </div>
          </div>
        </div>

        {/* Recent Games */}
        <div className="section">
          <h3 className="section-title">Recent Games</h3>
          <div className="games-list">
            {recent_games.map((game, idx) => (
              <div key={idx} className={`game-item ${game.result === 'W' ? 'win' : 'loss'}`}>
                <div className="game-result">{game.result}</div>
                <div className="game-details">
                  <div className="game-opponent">vs {game.opponent}</div>
                  <div className="game-score">{game.score}</div>
                </div>
                <div className="game-date">{new Date(game.date).toLocaleDateString()}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Key Players */}
        <div className="section">
          <h3 className="section-title">Key Players</h3>
          <div className="players-list">
            {key_players.map((player, idx) => (
              <div key={idx} className="player-item">
                <div className="player-header">
                  <span className="player-number">#{player.number}</span>
                  <span className="player-name">{player.name}</span>
                  <span className="player-position">{player.position}</span>
                </div>
                <div className="player-stats">{player.stats}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Next Game */}
        {next_game && (
          <div className="section next-game-section">
            <h3 className="section-title">Next Game</h3>
            <div className="next-game">
              <div className="next-game-opponent">vs {next_game.opponent}</div>
              <div className="next-game-details">
                {new Date(next_game.date).toLocaleDateString()} • {next_game.location}
              </div>
            </div>
          </div>
        )}
      </>
    );
  };

  return (
    <div id="team-info-root">
      <style>{`
        #team-info-root {
          font-family: system-ui, -apple-system, sans-serif;
          padding: 20px;
          max-width: 700px;
          margin: 0 auto;
        }
        .team-header {
          display: flex;
          align-items: center;
          gap: 20px;
          margin-bottom: 30px;
          padding: 20px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 12px;
          color: white;
        }
        .team-logo {
          font-size: 64px;
          line-height: 1;
        }
        .team-header-info {
          flex: 1;
        }
        .team-name {
          margin: 0 0 8px 0;
          font-size: 28px;
          font-weight: bold;
        }
        .team-meta {
          font-size: 14px;
          opacity: 0.9;
          margin-bottom: 4px;
        }
        .team-record {
          font-size: 18px;
          font-weight: 600;
          margin-top: 8px;
        }
        .section {
          margin-bottom: 24px;
          background: #f9fafb;
          border-radius: 8px;
          padding: 16px;
        }
        .section-title {
          margin: 0 0 16px 0;
          font-size: 18px;
          font-weight: 600;
          color: #1f2937;
        }
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
          gap: 12px;
        }
        .stat-item {
          background: white;
          padding: 12px;
          border-radius: 6px;
          text-align: center;
        }
        .stat-label {
          font-size: 12px;
          color: #6b7280;
          margin-bottom: 4px;
        }
        .stat-value {
          font-size: 20px;
          font-weight: bold;
          color: #1f2937;
        }
        .games-list {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
        .game-item {
          display: flex;
          align-items: center;
          gap: 12px;
          background: white;
          padding: 12px;
          border-radius: 6px;
          border-left: 4px solid #e5e7eb;
        }
        .game-item.win {
          border-left-color: #10b981;
        }
        .game-item.loss {
          border-left-color: #ef4444;
        }
        .game-result {
          font-weight: bold;
          font-size: 18px;
          width: 24px;
        }
        .game-item.win .game-result {
          color: #10b981;
        }
        .game-item.loss .game-result {
          color: #ef4444;
        }
        .game-details {
          flex: 1;
        }
        .game-opponent {
          font-weight: 500;
        }
        .game-score {
          font-size: 14px;
          color: #6b7280;
        }
        .game-date {
          font-size: 12px;
          color: #9ca3af;
        }
        .players-list {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
        .player-item {
          background: white;
          padding: 12px;
          border-radius: 6px;
        }
        .player-header {
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 4px;
        }
        .player-number {
          font-weight: bold;
          color: #6b7280;
          min-width: 32px;
        }
        .player-name {
          font-weight: 600;
          flex: 1;
        }
        .player-position {
          background: #e5e7eb;
          padding: 2px 8px;
          border-radius: 4px;
          font-size: 12px;
          font-weight: 600;
          color: #4b5563;
        }
        .player-stats {
          font-size: 13px;
          color: #6b7280;
          margin-left: 40px;
        }
        .next-game-section {
          background: #fef3c7;
          border: 2px solid #fbbf24;
        }
        .next-game {
          text-align: center;
        }
        .next-game-opponent {
          font-size: 20px;
          font-weight: bold;
          margin-bottom: 8px;
          color: #92400e;
        }
        .next-game-details {
          font-size: 14px;
          color: #78350f;
        }
      `}</style>
      <div className="team-info-container">
        {renderTeamInfo()}
      </div>
    </div>
  );
};

export default TeamInfoWidget;
