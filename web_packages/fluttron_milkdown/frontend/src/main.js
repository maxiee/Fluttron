import { Crepe } from '@milkdown/crepe';
import '@milkdown/crepe/theme/common/style.css';
import '@milkdown/crepe/theme/frame.css';

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

const editorInstances = new Map();

const normalizeConfig = (config) => {
  if (typeof config === 'string') {
    return {
      initialMarkdown: config,
      theme: 'frame',
      readonly: false,
      features: { ...DEFAULT_FEATURES },
    };
  }
  if (config == null || typeof config !== 'object') {
    return {
      initialMarkdown: '',
      theme: 'frame',
      readonly: false,
      features: { ...DEFAULT_FEATURES },
    };
  }
  return {
    initialMarkdown: typeof config.initialMarkdown === 'string' ? config.initialMarkdown : '',
    theme: typeof config.theme === 'string' ? config.theme : 'frame',
    readonly: config.readonly === true,
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

const clearThemeClasses = (container) => {
  const themeClasses = [
    'milkdown-theme-frame', 'milkdown-theme-frame-dark',
    'milkdown-theme-classic', 'milkdown-theme-classic-dark',
    'milkdown-theme-nord', 'milkdown-theme-nord-dark',
  ];
  themeClasses.forEach(cls => container.classList.remove(cls));
};

const applyTheme = (container, themeName) => {
  clearThemeClasses(container);
  const themeClass = `milkdown-theme-${themeName}`;
  container.classList.add(themeClass);
};

const destroyEditor = async (viewId) => {
  const instance = editorInstances.get(viewId);
  if (!instance) return;

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

  const crepeFeatures = mapToCrepeFeatures(options.features);

  const crepe = new Crepe({
    root: editorMount,
    defaultValue: options.initialMarkdown,
    features: crepeFeatures,
  });

  await crepe.create();

  if (options.readonly) {
    crepe.setReadonly(true);
  }

  crepe.on((listener) => {
    listener.markdownUpdated((ctx, markdown, prevMarkdown) => {
      emitEditorChange(viewId, markdown);
    });
  });

  editorMount.addEventListener('focus', () => emitEditorFocus(viewId), true);
  editorMount.addEventListener('blur', () => emitEditorBlur(viewId), true);

  editorInstances.set(viewId, { crepe, container, theme: options.theme });

  applyTheme(container, options.theme);

  emitEditorReady(viewId);
  emitEditorChange(viewId, options.initialMarkdown);
};

// Flutter HtmlElementView expects the factory to return an HTMLElement synchronously.
const createMilkdownEditorView = (viewId, config) => {
  const options = normalizeConfig(config);

  const container = document.createElement('div');
  container.id = `fluttron-milkdown-${viewId}`;
  container.className = 'fluttron-milkdown';

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

  initializeCrepeEditor(viewId, container, options).catch((error) => {
    console.error('[fluttron_milkdown] Failed to initialize editor:', error);
    editorMount.innerHTML = `
      <div style="padding: 16px; color: #dc2626; background: #fef2f2; border-radius: 8px;">
        Failed to initialize editor: ${error.message}
      </div>
    `;
  });

  return container;
};

window.fluttronCreateMilkdownEditorView = createMilkdownEditorView;

/**
 * Control channel for runtime editor manipulation.
 * 
 * @param {number} viewId - The view identifier
 * @param {string} action - Action to perform
 * @param {object|null} params - Action parameters
 * @returns {{ok: boolean, result?: any, error?: string}}
 */
window.fluttronMilkdownControl = (viewId, action, params) => {
  // Validate viewId
  if (typeof viewId !== 'number' && typeof viewId !== 'string') {
    return { ok: false, error: `Invalid viewId: expected number or string, got ${typeof viewId}` };
  }

  const viewIdKey = typeof viewId === 'string' ? parseInt(viewId, 10) : viewId;
  
  // Find editor instance
  const instance = editorInstances.get(viewIdKey);
  if (!instance) {
    return { ok: false, error: `No editor instance for viewId ${viewIdKey}` };
  }

  const { crepe, container } = instance;

  try {
    switch (action) {
      case 'getContent':
        return { ok: true, result: crepe.getMarkdown() };

      case 'setContent':
        if (params == null || typeof params.content !== 'string') {
          return { ok: false, error: 'setContent requires params.content (string)' };
        }
        crepe.setMarkdown(params.content);
        return { ok: true };

      case 'focus':
        crepe.editor?.focus();
        return { ok: true };

      case 'insertText':
        if (params == null || typeof params.text !== 'string') {
          return { ok: false, error: 'insertText requires params.text (string)' };
        }
        crepe.editor?.insertText(params.text);
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
        const validThemes = ['frame', 'frame-dark', 'classic', 'classic-dark', 'nord', 'nord-dark'];
        if (!validThemes.includes(params.theme)) {
          return { ok: false, error: `Invalid theme "${params.theme}". Valid themes: ${validThemes.join(', ')}` };
        }
        applyTheme(container, params.theme);
        instance.theme = params.theme;
        return { ok: true };
      }

      default:
        return { ok: false, error: `Unknown action: ${action}` };
    }
  } catch (error) {
    return { ok: false, error: `Action "${action}" failed: ${error.message}` };
  }
};
