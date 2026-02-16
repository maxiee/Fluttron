import { Crepe } from '@milkdown/crepe';
import '@milkdown/crepe/theme/common/style.css';
import '@milkdown/crepe/theme/frame.css';

const EVENT_PREFIX = 'fluttron.milkdown.editor';

/**
 * Feature toggle configuration.
 * All features are enabled by default.
 * This can be extended in the future to allow fine-grained control.
 */
const DEFAULT_FEATURES = {
  // Code block syntax highlighting with CodeMirror
  codeMirror: true,
  // Bullet lists, ordered lists, and task lists (GFM)
  listItem: true,
  // Link tooltips
  linkTooltip: true,
  // Enhanced cursor experience
  cursor: true,
  // Image block support
  imageBlock: true,
  // Block editing (slash commands, drag-and-drop)
  blockEdit: true,
  // Formatting toolbar
  toolbar: true,
  // Placeholder text
  placeholder: true,
  // GFM tables
  table: true,
  // LaTeX math formulas
  latex: true,
};

const editorInstances = new Map();

const emitEditorChange = (viewId, markdown) => {
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

const emitEditorReady = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.ready`, {
    detail: { viewId },
  }));
};

const emitEditorFocus = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.focus`, {
    detail: { viewId },
  }));
};

const emitEditorBlur = (viewId) => {
  window.dispatchEvent(new CustomEvent(`${EVENT_PREFIX}.blur`, {
    detail: { viewId },
  }));
};

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
