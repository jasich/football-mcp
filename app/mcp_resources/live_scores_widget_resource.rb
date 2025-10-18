# frozen_string_literal: true

class LiveScoresWidgetResource
  # Add version for cache busting during development
  VERSION = "v3"
  URI = "ui://widget/live-scores.html?#{VERSION}"

  class << self
    def to_resource
      MCP::Resource.new(
        uri: URI,
        name: "Live Scores Widget",
        description: "HTML template for displaying live football scores",
        mime_type: "text/html+skybridge"
      )
    end

    def read
      <<~HTML
        <div id="live-scores-root">
          <style>
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
          </style>
          <div class="scores-container">
            <h2>🏟️ Live Football Scores</h2>
            <div id="scores-content"></div>
          </div>
          <script type="module">
            // The OpenAI Apps SDK injects tool output into window.openai.toolOutput
            // This contains: { structuredContent, content, _meta }

            function renderScores() {
              const container = document.getElementById('scores-content');

              // Debug: log what we receive
              console.log('window.openai:', window.openai);
              console.log('window.openai.toolOutput:', window.openai?.toolOutput);

              // ChatGPT injects structuredContent as window.openai.toolOutput
              // So toolOutput IS the structuredContent object
              const toolOutput = window.openai?.toolOutput;

              if (!toolOutput) {
                container.innerHTML = '<p>Waiting for data... (checking window.openai.toolOutput)</p>';
                return;
              }

              // Access matches directly from toolOutput (which is structuredContent)
              const matches = toolOutput.matches || [];
              const lastUpdated = toolOutput.lastUpdated;

              if (matches.length === 0) {
                // Debug output to see what we actually received
                container.innerHTML = `
                  <p>No live matches available</p>
                  <details style="margin-top: 20px; font-size: 12px; font-family: monospace;">
                    <summary>Debug Info (click to expand)</summary>
                    <pre style="background: #f5f5f5; padding: 10px; overflow: auto; max-height: 300px;">
toolOutput: ${JSON.stringify(toolOutput, null, 2)}
                    </pre>
                  </details>
                `;
                return;
              }

              const matchesByLeague = {};
              matches.forEach(match => {
                if (!matchesByLeague[match.league]) {
                  matchesByLeague[match.league] = [];
                }
                matchesByLeague[match.league].push(match);
              });

              let html = '';

              // Show last updated timestamp
              if (lastUpdated) {
                const date = new Date(lastUpdated);
                html += `<div style="text-align: center; color: #666; font-size: 12px; margin-bottom: 16px;">`;
                html += `Last updated: ${date.toLocaleTimeString()}`;
                html += `</div>`;
              }

              Object.entries(matchesByLeague).forEach(([league, matches]) => {
                html += `<div class="league-section">`;
                html += `<div class="league-title">${league}</div>`;
                matches.forEach(match => {
                  html += `<div class="match">`;
                  html += `<div class="team-row">`;
                  html += `<span class="team-name">`;
                  if (match.possession === 'home') html += `<span class="possession">🏈</span>`;
                  html += `${match.home_team}</span>`;
                  html += `<span class="team-score">${match.home_score}</span>`;
                  html += `</div>`;
                  html += `<div class="team-row">`;
                  html += `<span class="team-name">`;
                  if (match.possession === 'away') html += `<span class="possession">🏈</span>`;
                  html += `${match.away_team}</span>`;
                  html += `<span class="team-score">${match.away_score}</span>`;
                  html += `</div>`;
                  html += `<div class="match-status">${match.quarter} - ${match.time_remaining}</div>`;
                  html += `</div>`;
                });
                html += `</div>`;
              });

              container.innerHTML = html;
            }

            // Polling function to check for data
            let attempts = 0;
            const maxAttempts = 100; // 10 seconds total

            function checkAndRender() {
              attempts++;
              console.log(`Attempt ${attempts}: Checking for data...`, window.openai?.toolOutput);

              if (window.openai?.toolOutput) {
                console.log('Data found! Rendering...');
                renderScores();
                return true;
              }

              if (attempts >= maxAttempts) {
                console.log('Max attempts reached, giving up');
                document.getElementById('scores-content').innerHTML =
                  '<p>Failed to load data after 10 seconds. Please refresh.</p>';
                return true;
              }

              return false;
            }

            // Try immediately
            if (!checkAndRender()) {
              // If not ready, poll every 100ms
              const checkInterval = setInterval(() => {
                if (checkAndRender()) {
                  clearInterval(checkInterval);
                }
              }, 100);
            }
          </script>
        </div>
      HTML
    end

    def meta
      {
        "openai/widgetPrefersBorder" => true,
        "openai/widgetDomain" => "https://chatgpt.com",
        "openai/widgetCSP" => {
          "connect_domains" => ["https://chatgpt.com"],
          "resource_domains" => ["https://*.oaistatic.com"]
        }
      }
    end
  end
end
