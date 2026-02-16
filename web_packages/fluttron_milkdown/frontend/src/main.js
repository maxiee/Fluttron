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
  container.classList.add('milkdown-theme-frame');
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
