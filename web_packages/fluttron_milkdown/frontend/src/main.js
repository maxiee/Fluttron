import { Crepe } from '@milkdown/crepe';
import { replaceAll } from '@milkdown/kit/utils';
import '@milkdown/crepe/theme/common/style.css';
import '@milkdown/crepe/theme/frame.css';
import '@milkdown/crepe/theme/frame-dark.css';
import '@milkdown/crepe/theme/nord.css';
import '@milkdown/crepe/theme/nord-dark.css';
import './theme-overrides.css';

import {
  emitEditorChange,
  emitEditorReady,
  emitEditorFocus,
  emitEditorBlur,
} from './events.js';

const DEFAULT_FEATURES = {
  codeMirror: true,
  listItem: true,
  linkTooltip: true,
  cursor: true,
  imageBlock: true,
  blockEdit: true,
  toolbar: true,
  placeholder: true,
  table: true,
  latex: true,
};

const VALID_THEMES = ['frame', 'frame-dark', 'nord', 'nord-dark'];

const editorInstances = new Map();
const lifecycleObservers = new Map();

const normalizeTheme = (themeName) => {
  if (typeof themeName !== 'string') {
    return 'frame';
  }
  return VALID_THEMES.includes(themeName) ? themeName : 'frame';
};

const normalizeInstanceToken = (instanceToken) => {
  if (typeof instanceToken !== 'string') {
    return null;
  }
  const trimmed = instanceToken.trim();
  return trimmed.length > 0 ? trimmed : null;
};

const normalizeConfig = (config) => {
  if (typeof config === 'string') {
    return {
      initialMarkdown: config,
      theme: 'frame',
      readonly: false,
      instanceToken: null,
      features: { ...DEFAULT_FEATURES },
    };
  }
  if (config == null || typeof config !== 'object') {
    return {
      initialMarkdown: '',
      theme: 'frame',
      readonly: false,
      instanceToken: null,
      features: { ...DEFAULT_FEATURES },
    };
  }
  return {
    initialMarkdown: typeof config.initialMarkdown === 'string' ? config.initialMarkdown : '',
    theme: normalizeTheme(config.theme),
    readonly: config.readonly === true,
    instanceToken: normalizeInstanceToken(config.instanceToken),
    features: {
      ...DEFAULT_FEATURES,
      ...(typeof config.features === 'object' && config.features !== null ? config.features : {}),
    },
  };
};

const mapToCrepeFeatures = (features) => ({
  [Crepe.Feature.CodeMirror]: features.codeMirror !== false,
  [Crepe.Feature.ListItem]: features.listItem !== false,
  [Crepe.Feature.LinkTooltip]: features.linkTooltip !== false,
  [Crepe.Feature.Cursor]: features.cursor !== false,
  [Crepe.Feature.ImageBlock]: features.imageBlock !== false,
  [Crepe.Feature.BlockEdit]: features.blockEdit !== false,
  [Crepe.Feature.Toolbar]: features.toolbar !== false,
  [Crepe.Feature.Placeholder]: features.placeholder !== false,
  [Crepe.Feature.Table]: features.table !== false,
  [Crepe.Feature.Latex]: features.latex !== false,
});

const clearThemeClasses = (...elements) => {
  VALID_THEMES.forEach((themeName) => {
    const className = `milkdown-theme-${themeName}`;
    elements.forEach((element) => {
      if (element) {
        element.classList.remove(className);
      }
    });
  });
};

const applyTheme = (container, editorMount, themeName) => {
  const normalizedTheme = normalizeTheme(themeName);
  clearThemeClasses(container, editorMount);
  const themeClass = `milkdown-theme-${normalizedTheme}`;
  container.classList.add(themeClass);
  if (editorMount) {
    editorMount.classList.add(themeClass);
  }
};

const ensureMilkdownRootClass = (editorMount) => {
  if (editorMount.classList.contains('milkdown')) {
    return;
  }

  // Crepe styles and theme variables are scoped to `.milkdown`.
  // Make sure the mount root always matches this selector.
  editorMount.classList.add('milkdown');
};

const disconnectLifecycleObserver = (viewId) => {
  const observer = lifecycleObservers.get(viewId);
  if (!observer) {
    return;
  }
  observer.disconnect();
  lifecycleObservers.delete(viewId);
};

const attachLifecycleObserver = (viewId, container) => {
  disconnectLifecycleObserver(viewId);
  if (typeof MutationObserver !== 'function') {
    return;
  }

  const observerRoot = document.documentElement;
  if (!observerRoot) {
    return;
  }

  const observer = new MutationObserver(() => {
    if (container.isConnected) {
      return;
    }

    disconnectLifecycleObserver(viewId);
    destroyEditor(viewId).catch((error) => {
      console.warn('[fluttron_milkdown] Failed to dispose editor instance:', error);
    });
  });

  observer.observe(observerRoot, { childList: true, subtree: true });
  lifecycleObservers.set(viewId, observer);
};

const destroyEditor = async (viewId) => {
  disconnectLifecycleObserver(viewId);

  const instance = editorInstances.get(viewId);
  if (!instance) {
    return;
  }

  if (instance.editorMount && instance.handleFocus) {
    instance.editorMount.removeEventListener('focus', instance.handleFocus, true);
  }
  if (instance.editorMount && instance.handleBlur) {
    instance.editorMount.removeEventListener('blur', instance.handleBlur, true);
  }

  try {
    await instance.crepe.destroy();
  } catch (_) {
    // Swallow errors during cleanup
  }
  editorInstances.delete(viewId);
};

const initializeCrepeEditor = async (viewId, container, options) => {
  await destroyEditor(viewId);

  const editorMount = container.querySelector('.fluttron-milkdown__editor-mount');
  if (!editorMount) {
    throw new Error('Missing editor mount element.');
  }
  ensureMilkdownRootClass(editorMount);

  const crepeFeatures = mapToCrepeFeatures(options.features);
  const instanceToken = normalizeInstanceToken(options.instanceToken);

  const crepe = new Crepe({
    root: editorMount,
    defaultValue: options.initialMarkdown,
    features: crepeFeatures,
  });

  await crepe.create();
  ensureMilkdownRootClass(editorMount);

  if (options.readonly) {
    crepe.setReadonly(true);
  }

  crepe.on((listener) => {
    listener.markdownUpdated((ctx, markdown, prevMarkdown) => {
      emitEditorChange(viewId, markdown, instanceToken);
    });
  });

  const handleFocus = () => emitEditorFocus(viewId, instanceToken);
  const handleBlur = () => emitEditorBlur(viewId, instanceToken);
  editorMount.addEventListener('focus', handleFocus, true);
  editorMount.addEventListener('blur', handleBlur, true);

  editorInstances.set(viewId, {
    crepe,
    container,
    editorMount,
    handleFocus,
    handleBlur,
    instanceToken,
    theme: options.theme,
  });

  applyTheme(container, editorMount, options.theme);

  emitEditorReady(viewId, instanceToken);
  emitEditorChange(viewId, options.initialMarkdown, instanceToken);
};

// Flutter HtmlElementView expects the factory to return an HTMLElement synchronously.
const createMilkdownEditorView = (viewId, config) => {
  const options = normalizeConfig(config);

  const container = document.createElement('div');
  container.id = `fluttron-milkdown-${viewId}`;
  container.className = 'fluttron-milkdown';
  if (options.instanceToken) {
    container.dataset.instanceToken = options.instanceToken;
  }

  container.style.cssText = `
    width: 100%;
    height: 100%;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
  `;

  const editorMount = document.createElement('div');
  editorMount.className = 'fluttron-milkdown__editor-mount';
  editorMount.style.cssText = `
    flex: 1;
    min-height: 0;
    overflow: auto;
  `;

  container.appendChild(editorMount);
  attachLifecycleObserver(viewId, container);

  initializeCrepeEditor(viewId, container, options).catch((error) => {
    console.error('[fluttron_milkdown] Failed to initialize editor:', error);
    const message = error instanceof Error ? error.message : String(error);
    editorMount.innerHTML = `
      <div style="padding: 16px; color: #dc2626; background: #fef2f2; border-radius: 8px;">
        Failed to initialize editor: ${message}
      </div>
    `;
  });

  return container;
};

window.fluttronCreateMilkdownEditorView = createMilkdownEditorView;

const resolveViewId = (rawViewId) => {
  if (typeof rawViewId === 'number') {
    return Number.isInteger(rawViewId) ? rawViewId : null;
  }

  if (typeof rawViewId === 'string' && rawViewId.trim().length > 0) {
    const parsed = Number(rawViewId);
    return Number.isInteger(parsed) ? parsed : null;
  }

  return null;
};

/**
 * Control channel for runtime editor manipulation.
 * 
 * @param {number} viewId - The view identifier
 * @param {string} action - Action to perform
 * @param {object|null} params - Action parameters
 * @returns {{ok: boolean, result?: any, error?: string}}
 */
window.fluttronMilkdownControl = (viewId, action, params) => {
  const viewIdKey = resolveViewId(viewId);
  if (viewIdKey == null) {
    return {
      ok: false,
      error: `Invalid viewId: expected an integer, got ${typeof viewId}`,
    };
  }
  
  // Find editor instance
  const instance = editorInstances.get(viewIdKey);
  if (!instance) {
    return { ok: false, error: `No editor instance for viewId ${viewIdKey}` };
  }

  const { crepe, container, editorMount } = instance;

  try {
    switch (action) {
      case 'getContent':
        return { ok: true, result: crepe.getMarkdown() };

      case 'setContent':
        if (params == null || typeof params.content !== 'string') {
          return { ok: false, error: 'setContent requires params.content (string)' };
        }
        if (!crepe.editor || typeof crepe.editor.action !== 'function') {
          return { ok: false, error: 'setContent is unavailable: editor API is not ready.' };
        }
        crepe.editor.action(replaceAll(params.content));
        return { ok: true };

      case 'focus':
        if (!crepe.editor || typeof crepe.editor.focus !== 'function') {
          return { ok: false, error: 'focus is unavailable: editor API is not ready.' };
        }
        crepe.editor.focus();
        return { ok: true };

      case 'insertText':
        if (params == null || typeof params.text !== 'string') {
          return { ok: false, error: 'insertText requires params.text (string)' };
        }
        if (!crepe.editor || typeof crepe.editor.insertText !== 'function') {
          return { ok: false, error: 'insertText is unavailable: editor API is not ready.' };
        }
        crepe.editor.insertText(params.text);
        return { ok: true };

      case 'setReadonly':
        if (params == null || typeof params.readonly !== 'boolean') {
          return { ok: false, error: 'setReadonly requires params.readonly (boolean)' };
        }
        crepe.setReadonly(params.readonly);
        return { ok: true };

      case 'setTheme': {
        if (params == null || typeof params.theme !== 'string') {
          return { ok: false, error: 'setTheme requires params.theme (string)' };
        }
        if (!VALID_THEMES.includes(params.theme)) {
          return { ok: false, error: `Invalid theme "${params.theme}". Valid themes: ${VALID_THEMES.join(', ')}` };
        }
        applyTheme(container, editorMount, params.theme);
        instance.theme = params.theme;
        return { ok: true };
      }

      default:
        return { ok: false, error: `Unknown action: ${action}` };
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { ok: false, error: `Action "${action}" failed: ${message}` };
  }
};
