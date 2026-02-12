(() => {
  // src/main.js
  var EXAMPLE_CHANGE_EVENT = "fluttron.template_package.example.change";
  var DEFAULT_INITIAL_CONTENT = "Hello from web package!\n\nThis is a reusable component.";
  var emitContentChanged = (content) => {
    window.dispatchEvent(
      new CustomEvent(EXAMPLE_CHANGE_EVENT, {
        detail: {
          content,
          timestamp: Date.now()
        }
      })
    );
  };
  var createTemplatePackageExampleView = (viewId, initialContent) => {
    const content = typeof initialContent === "string" && initialContent.trim() ? initialContent : DEFAULT_INITIAL_CONTENT;
    const container = document.createElement("div");
    container.id = `fluttron-web-package-${viewId}`;
    container.className = "template-package-example";
    container.style.cssText = `
    width: 100%;
    height: 100%;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
    gap: 12px;
    padding: 16px;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    background: #f9fafb;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  `;
    const header = document.createElement("div");
    header.className = "template-package-example__header";
    header.style.cssText = `
    display: flex;
    align-items: center;
    gap: 8px;
  `;
    const badge = document.createElement("span");
    badge.className = "template-package-example__badge";
    badge.textContent = "Web Package";
    badge.style.cssText = `
    display: inline-flex;
    padding: 2px 8px;
    font-size: 11px;
    font-weight: 600;
    color: #1d4ed8;
    background: #dbeafe;
    border-radius: 4px;
  `;
    const title = document.createElement("span");
    title.className = "template-package-example__title";
    title.textContent = "Example Component";
    title.style.cssText = `
    font-size: 14px;
    font-weight: 500;
    color: #374151;
  `;
    header.append(badge, title);
    const editor = document.createElement("div");
    editor.className = "template-package-example__editor";
    editor.contentEditable = "true";
    editor.innerText = content;
    editor.style.cssText = `
    flex: 1;
    min-height: 80px;
    padding: 12px;
    font-size: 14px;
    line-height: 1.5;
    color: #1f2937;
    background: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 6px;
    outline: none;
    resize: none;
    overflow: auto;
  `;
    editor.addEventListener("input", () => {
      const currentContent = (editor.innerText || "").replace(/\r\n/g, "\n");
      emitContentChanged(currentContent);
    });
    container.append(header, editor);
    emitContentChanged(content);
    return container;
  };
  window.fluttronCreateTemplatePackageExampleView = createTemplatePackageExampleView;
})();
//# sourceMappingURL=main.js.map
