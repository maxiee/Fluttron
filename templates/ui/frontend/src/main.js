const createTemplateHtmlView = (viewId) => {
  const root = document.createElement('div');
  root.id = `fluttron-html-view-${viewId}`;
  root.style.width = '100%';
  root.style.height = '100%';
  root.style.boxSizing = 'border-box';
  root.style.display = 'flex';
  root.style.flexDirection = 'column';
  root.style.gap = '8px';
  root.style.padding = '12px';
  root.style.border = '1px solid #d0d7de';
  root.style.borderRadius = '8px';
  root.style.background = '#ffffff';
  root.style.fontFamily =
    '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';

  const title = document.createElement('div');
  title.textContent = 'Rendered by external JS';
  title.style.fontSize = '14px';
  title.style.fontWeight = '600';
  title.style.color = '#1f2328';

  const editor = document.createElement('div');
  editor.contentEditable = 'true';
  editor.style.flex = '1';
  editor.style.minHeight = '96px';
  editor.style.padding = '10px';
  editor.style.border = '1px solid #d0d7de';
  editor.style.borderRadius = '6px';
  editor.style.background = '#f6f8fa';
  editor.style.outline = 'none';
  editor.style.overflow = 'auto';
  editor.innerHTML =
    '<p><strong>Hello from external HTML/JS.</strong></p><p>Edit this text to verify embedded DOM rendering inside Flutter.</p>';

  const status = document.createElement('div');
  status.style.fontSize = '12px';
  status.style.color = '#57606a';

  const updateStatus = () => {
    const content = (editor.innerText || '').trim();
    status.textContent = `Characters: ${content.length} | Last input: ${new Date().toLocaleTimeString()}`;
  };

  editor.addEventListener('input', updateStatus);
  updateStatus();

  root.append(title, editor, status);
  return root;
};

window.fluttronCreateTemplateHtmlView = createTemplateHtmlView;
