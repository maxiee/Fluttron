/**
 * Event dispatch module for fluttron_milkdown.
 * 
 * All events use CustomEvent with a 'fluttron.milkdown.editor' prefix
 * and include viewId in the detail payload for multi-instance filtering.
 */

const EVENT_PREFIX = 'fluttron.milkdown.editor';

/**
 * Emits a change event when the editor content is modified.
 * 
 * @param {number} viewId - The view identifier for filtering
 * @param {string} markdown - The current markdown content
 */
export const emitEditorChange = (viewId, markdown) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.change`, {
    detail: {
      viewId,
      markdown,
      characterCount: markdown.length,
      lineCount: markdown.split('\n').length,
      updatedAt: new Date().toISOString(),
    },
  }));
};

/**
 * Emits a ready event when the editor is fully initialized.
 * 
 * @param {number} viewId - The view identifier for filtering
 */
export const emitEditorReady = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.ready`, {
    detail: { viewId },
  }));
};

/**
 * Emits a focus event when the editor gains focus.
 * 
 * @param {number} viewId - The view identifier for filtering
 */
export const emitEditorFocus = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.focus`, {
    detail: { viewId },
  }));
};

/**
 * Emits a blur event when the editor loses focus.
 * 
 * @param {number} viewId - The view identifier for filtering
 */
export const emitEditorBlur = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.blur`, {
    detail: { viewId },
  }));
};

// Export the event prefix for external use
export const EVENT_NAMES = {
  CHANGE: `${EVENT_PREFIX}.change`,
  READY: `${EVENT_PREFIX}.ready`,
  FOCUS: `${EVENT_PREFIX}.focus`,
  BLUR: `${EVENT_PREFIX}.blur`,
};
