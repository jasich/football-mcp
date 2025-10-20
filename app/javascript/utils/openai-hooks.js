import { useSyncExternalStore } from 'react';

// Custom hook to subscribe to window.openai global changes
// Based on OpenAI Apps SDK documentation pattern
const SET_GLOBALS_EVENT_TYPE = 'openai:set_globals';

/**
 * Subscribe to changes in window.openai global variables
 * @param {string} key - The key to watch in window.openai
 * @returns {any} The current value of window.openai[key]
 */
export function useOpenAiGlobal(key) {
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

/**
 * Convenience hook to access tool output data
 * @returns {any} The current tool output from window.openai.toolOutput
 */
export function useToolOutput() {
  return useOpenAiGlobal('toolOutput');
}
