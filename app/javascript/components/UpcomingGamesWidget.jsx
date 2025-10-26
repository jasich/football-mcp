import React, { useState } from 'react';
import { useToolOutput } from '../utils/openai-hooks';

const UpcomingGamesWidget = () => {
  const toolOutput = useToolOutput();
  const [recentSelection, setRecentSelection] = useState(null);

  if (!toolOutput) {
    return <p>Loading upcoming games...</p>;
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
    <div id="upcoming-games-root">
      <style>{`
        #upcoming-games-root {
          font-family: system-ui, -apple-system, sans-serif;
          padding: 20px;
        }
        .schedule-container {
          max-width: 680px;
          margin: 0 auto;
        }
        .widget-header {
          border-left: 6px solid ${primaryColor || '#111827'};
          background: #f9fafb;
          padding: 16px;
          border-radius: 10px;
          margin-bottom: 24px;
        }
        .widget-header h2 {
          margin: 0;
          font-size: 26px;
        }
        .widget-subtitle {
          color: #6b7280;
          font-size: 14px;
          margin-top: 4px;
        }
        .game-card {
          background: white;
          border-radius: 10px;
          padding: 16px;
          margin-bottom: 16px;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
          border: 1px solid #e5e7eb;
        }
        .game-meta {
          display: flex;
          flex-wrap: wrap;
          gap: 12px;
          font-size: 14px;
          color: #4b5563;
          margin: 8px 0 12px;
        }
        .game-opponent {
          font-size: 18px;
          font-weight: 600;
        }
        .cta-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 12px;
          flex-wrap: wrap;
        }
        .buy-button {
          background: ${primaryColor || '#2563eb'};
          color: white;
          border: none;
          border-radius: 999px;
          padding: 10px 20px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          display: inline-flex;
          align-items: center;
          gap: 6px;
          transition: transform 150ms ease, box-shadow 150ms ease;
        }
        .buy-button:hover {
          transform: translateY(-1px);
          box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
        }
        .buy-button:active {
          transform: translateY(0);
          box-shadow: none;
        }
        .recent-selection {
          margin-top: 16px;
          font-size: 13px;
          color: #374151;
          background: #ecfccb;
          border: 1px solid #bef264;
          border-radius: 8px;
          padding: 10px 14px;
        }
      `}</style>
      <div className="schedule-container">
        <div className="widget-header">
          <h2>{teamName}</h2>
          <div className="widget-subtitle">
            Upcoming schedule • {league}
          </div>
        </div>

        {upcomingGames.length === 0 ? (
          <p>No upcoming games found.</p>
        ) : (
          upcomingGames.map((game, index) => (
            <div key={`${game.opponent}-${game.date}-${index}`} className="game-card">
              <div className="game-opponent">vs {game.opponent}</div>
              <div className="game-meta">
                <span>{new Date(game.date).toLocaleDateString()}</span>
                <span>{game.kickoff}</span>
                <span>{game.location} • {game.venue}</span>
                <span>{game.theme}</span>
              </div>
              <div className="cta-row">
                <div>
                  <strong>Tickets from</strong> <span>${game.starting_price || '89'}</span>
                </div>
                <button
                  type="button"
                  className="buy-button"
                  onClick={() => handleBuyTickets(game)}
                >
                  🎟️ Buy Tickets
                </button>
              </div>
            </div>
          ))
        )}

        {recentSelection && (
          <div className="recent-selection">
            Opening ticket info for {recentSelection.opponent} on {new Date(recentSelection.date).toLocaleDateString()}...
          </div>
        )}
      </div>
    </div>
  );
};

export default UpcomingGamesWidget;
