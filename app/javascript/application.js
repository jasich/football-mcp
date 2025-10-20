// Entry point for the build script in your package.json
import React from 'react';
import { createRoot } from 'react-dom/client';
import LiveScoresWidget from './components/LiveScoresWidget';
import TeamInfoWidget from './components/TeamInfoWidget';
// Import other widgets here as you create them
// import TeamStatsWidget from './components/TeamStatsWidget';

// Component registry - add new widgets here
const COMPONENT_REGISTRY = {
  'LiveScoresWidget': LiveScoresWidget,
  'TeamInfoWidget': TeamInfoWidget,
  // 'TeamStatsWidget': TeamStatsWidget,
};

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('react-root');
  const componentName = container?.getAttribute('data-component');

  if (!container) {
    console.error('React root container not found');
    return;
  }

  if (!componentName) {
    console.error('No component name specified in data-component attribute');
    return;
  }

  const Component = COMPONENT_REGISTRY[componentName];

  if (!Component) {
    console.error(`Component "${componentName}" not found in registry`);
    return;
  }

  const root = createRoot(container);
  root.render(<Component />);
});
