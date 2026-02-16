/**
 * Event dispatch module for fluttron_milkdown.
 * 
 * All events use CustomEvent with a 'fluttron.milkdown.editor' prefix
 * and include viewId in the detail payload for multi-instance filtering.
 */

const EVENT_PREFIX = 'fluttron.milkdown.editor';

const withInstanceToken = (detail, instanceToken) => {
  if (typeof instanceToken === 'string' && instanceToken.length > 0) {
    return {
      ...detail,
      instanceToken,
    };
  }
  return detail;
};

/**
 * Emits a change event when the editor content is modified.
 * 
 * @param {number} viewId - The view identifier for filtering
 * @param {string} markdown - The current markdown content
 * @param {string|null} instanceToken - Optional instance token for strict filtering
 */
export const emitEditorChange = (viewId, markdown, instanceToken = null) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.change`, {
    detail: withInstanceToken({
      viewId,
      markdown,
      characterCount: markdown.length,
      lineCount: markdown.split('\n').length,
      updatedAt: new Date().toISOString(),
    }, instanceToken),
  }));
};

/**
 * Emits a ready event when the editor is fully initialized.
 * 
 * @param {number} viewId - The view identifier for filtering
 * @param {string|null} instanceToken - Optional instance token for strict filtering
 */
export const emitEditorReady = (viewId, instanceToken = null) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.ready`, {
    detail: withInstanceToken({ viewId }, instanceToken),
  }));
};

/**
 * Emits a focus event when the editor gains focus.
 * 
 * @param {number} viewId - The view identifier for filtering
 * @param {string|null} instanceToken - Optional instance token for strict filtering
 */
export const emitEditorFocus = (viewId, instanceToken = null) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.focus`, {
    detail: withInstanceToken({ viewId }, instanceToken),
  }));
};

/**
 * Emits a blur event when the editor loses focus.
 * 
 * @param {number} viewId - The view identifier for filtering
 * @param {string|null} instanceToken - Optional instance token for strict filtering
 */
export const emitEditorBlur = (viewId, instanceToken = null) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.blur`, {
    detail: withInstanceToken({ viewId }, instanceToken),
  }));
};

// Export the event prefix for external use
export const EVENT_NAMES = {
  CHANGE: `${EVENT_PREFIX}.change`,
  READY: `${EVENT_PREFIX}.ready`,
  FOCUS: `${EVENT_PREFIX}.focus`,
  BLUR: `${EVENT_PREFIX}.blur`,
};
