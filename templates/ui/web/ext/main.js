(() => {
  // frontend/src/main.js
  var TEMPLATE_EDITOR_CHANGE_EVENT = "fluttron.template.editor.change";
  var DEFAULT_TEMPLATE_TEXT = "Hello from external HTML/JS.\n\nEdit this text to verify event bridge sync.";
  var normalizeInitialText = (value) => {
    if (typeof value === "string" && value.trim().length > 0) {
      return value;
    }
    return DEFAULT_TEMPLATE_TEXT;
  };
  var emitEditorChanged = (content, source) => {
    window.dispatchEvent(
      new CustomEvent(TEMPLATE_EDITOR_CHANGE_EVENT, {
        detail: {
          content,
          characterCount: content.length,
          updatedAt: (/* @__PURE__ */ new Date()).toISOString(),
          source
        }
      })
    );
  };
  var createTemplateHtmlView = (viewId, initialText) => {
    const root = document.createElement("div");
    root.id = `fluttron-html-view-${viewId}`;
    root.style.width = "100%";
    root.style.height = "100%";
    root.style.boxSizing = "border-box";
    root.style.display = "flex";
    root.style.flexDirection = "column";
    root.style.gap = "8px";
    root.style.padding = "12px";
    root.style.border = "1px solid #d0d7de";
    root.style.borderRadius = "8px";
    root.style.background = "#ffffff";
    root.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
    const title = document.createElement("div");
    title.textContent = "Rendered by external JS";
    title.style.fontSize = "14px";
    title.style.fontWeight = "600";
    title.style.color = "#1f2328";
    const editor = document.createElement("div");
    editor.contentEditable = "true";
    editor.style.flex = "1";
    editor.style.minHeight = "96px";
    editor.style.padding = "10px";
    editor.style.border = "1px solid #d0d7de";
    editor.style.borderRadius = "6px";
    editor.style.background = "#f6f8fa";
    editor.style.outline = "none";
    editor.style.overflow = "auto";
    editor.innerText = normalizeInitialText(initialText);
    const status = document.createElement("div");
    status.style.fontSize = "12px";
    status.style.color = "#57606a";
    const publishEditorState = (source) => {
      const content = (editor.innerText || "").replace(/\r\n/g, "\n");
      status.textContent = `Characters: ${content.length} | Last input: ${(/* @__PURE__ */ new Date()).toLocaleTimeString()}`;
      emitEditorChanged(content, source);
    };
    editor.addEventListener("input", () => {
      publishEditorState("input");
    });
    publishEditorState("init");
    root.append(title, editor, status);
    return root;
  };
  window.fluttronCreateTemplateHtmlView = createTemplateHtmlView;
})();
//# sourceMappingURL=main.js.map
