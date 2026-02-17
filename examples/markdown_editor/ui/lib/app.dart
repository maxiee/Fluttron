import 'dart:async';

import 'package:fluttron_milkdown/fluttron_milkdown.dart';
import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:fluttron_ui/fluttron_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/editor_state.dart';
import 'services/dialog_service_client.dart';
import 'services/file_service_client.dart';
import 'widgets/sidebar.dart';
import 'widgets/status_bar.dart';

const MilkdownTheme _defaultTheme = MilkdownTheme.nord;
const String _themeStorageKey = 'markdown_editor.theme';
const String _welcomeMarkdown = '''
# Markdown Editor

Welcome to the Fluttron markdown editor example.

## Getting Started

Click **Open Folder** to select a directory containing markdown files.

## Features

- File tree sidebar (`.md` files only)
- Milkdown WYSIWYG editor
- Runtime theme switching (persisted)
- Save with `Cmd/Ctrl + S`

## Next

More features will be added in upcoming versions:
- Create new files
''';

class MarkdownEditorApp extends StatefulWidget {
  const MarkdownEditorApp({super.key});

  @override
  State<MarkdownEditorApp> createState() => _MarkdownEditorAppState();
}

class _MarkdownEditorAppState extends State<MarkdownEditorApp> {
  final MilkdownController _controller = MilkdownController();
  final FluttronClient _client = FluttronClient();
  late final FileServiceClient _fileClient;
  late final DialogServiceClient _dialogClient;

  late EditorState _state = EditorState.initial(
    initialContent: _welcomeMarkdown,
    currentTheme: _defaultTheme,
  );

  bool _isEditorReady = false;
  String _statusMessage = 'Initializing editor...';

  @override
  void initState() {
    super.initState();
    _fileClient = FileServiceClient(_client);
    _dialogClient = DialogServiceClient(_client);
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final savedThemeValue = await _client.kvGet(_themeStorageKey);
      if (savedThemeValue != null) {
        final savedTheme = MilkdownTheme.tryParse(savedThemeValue);
        if (savedTheme != null && mounted) {
          setState(() {
            _state = _state.copyWith(currentTheme: savedTheme);
          });
          // If editor is already ready, apply the theme now
          if (_isEditorReady) {
            await _controller.setTheme(savedTheme);
          }
        }
      }
    } catch (error) {
      // Ignore theme loading errors - fall back to default
    }
  }

  Future<void> _openFolder() async {
    try {
      final path = await _dialogClient.openDirectory(title: 'Open Folder');

      if (path == null) {
        // User cancelled the dialog
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _state = _state.copyWith(isLoading: true, clearErrorMessage: true);
        _statusMessage = 'Loading files...';
      });

      // List directory contents
      final entries = await _fileClient.listDirectory(path);

      // Filter to only .md files
      final mdFiles = entries
          .where((e) => e.isFile && e.name.toLowerCase().endsWith('.md'))
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _state = _state.copyWith(
          currentDirectoryPath: path,
          fileTree: mdFiles,
          isLoading: false,
        );
        _statusMessage = 'Opened ${mdFiles.length} markdown files';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to open folder: $error',
        );
      });
    }
  }

  Future<void> _openFile(FileEntry file) async {
    // Skip if already open and editor is ready
    if (_state.currentFilePath == file.path && _isEditorReady) {
      return;
    }

    setState(() {
      _state = _state.copyWith(isLoading: true, clearErrorMessage: true);
      _statusMessage = 'Opening ${file.name}...';
    });

    try {
      // Read file content from Host
      final content = await _fileClient.readFile(file.path);

      if (!mounted) {
        return;
      }

      // Set content in editor if ready
      if (_isEditorReady) {
        await _controller.setContent(content);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _state = _state.copyWith(
          currentFilePath: file.path,
          currentContent: content,
          savedContent: content,
          characterCount: content.length,
          lineCount: _computeLineCount(content),
          isLoading: false,
        );
        _statusMessage = 'Opened ${file.name}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to open file: $error',
        );
      });
    }
  }

  Future<void> _saveCurrentDocument() async {
    if (!_isEditorReady) {
      return;
    }

    try {
      final String content = await _controller.getContent();
      final String? currentFilePath = _state.currentFilePath;

      if (currentFilePath != null && currentFilePath.isNotEmpty) {
        await _fileClient.writeFile(currentFilePath, content);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _state = _state.copyWith(
          currentContent: content,
          savedContent: content,
          characterCount: content.length,
          lineCount: _computeLineCount(content),
          clearErrorMessage: true,
        );
        _statusMessage = (currentFilePath != null && currentFilePath.isNotEmpty)
            ? 'Saved to disk'
            : 'Saved in memory (no file selected)';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _state.copyWith(errorMessage: 'Save failed: $error');
      });
    }
  }

  Future<void> _selectTheme(MilkdownTheme theme) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _state = _state.copyWith(currentTheme: theme, clearErrorMessage: true);
      _statusMessage = 'Theme: ${_themeLabel(theme)}';
    });

    // Persist theme preference to Host KV storage
    try {
      await _client.kvSet(_themeStorageKey, theme.value);
    } catch (error) {
      // Ignore persistence errors - theme still works in-memory
    }

    if (!_isEditorReady) {
      return;
    }

    try {
      await _controller.setTheme(theme);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _state.copyWith(errorMessage: 'Theme switch failed: $error');
      });
    }
  }

  void _handleEditorChanged(MilkdownChangeEvent event) {
    if (!mounted) {
      return;
    }
    setState(() {
      _state = _state.copyWith(
        currentContent: event.markdown,
        characterCount: event.characterCount,
        lineCount: event.lineCount,
        clearErrorMessage: true,
      );
      _statusMessage = _state.isDirty ? 'Unsaved changes' : 'Saved';
    });
  }

  Future<void> _handleEditorReady() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isEditorReady = true;
      _statusMessage = 'Editor ready';
    });

    // If a file was opened before the editor was ready, set its content now
    if (_state.currentContent != _welcomeMarkdown) {
      try {
        await _controller.setContent(_state.currentContent);
      } catch (error) {
        // Ignore setContent errors during ready callback
      }
    }

    if (_state.currentTheme != _defaultTheme) {
      await _selectTheme(_state.currentTheme);
    }
  }

  String get _displayFileName {
    final String? path = _state.currentFilePath;
    if (path == null || path.isEmpty) {
      return 'Untitled.md';
    }
    return path.split('/').last;
  }

  void _onSaveShortcut() {
    unawaited(_saveCurrentDocument());
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            _onSaveShortcut,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _onSaveShortcut,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              _buildToolbar(),
              if (_state.errorMessage != null) _buildErrorBanner(),
              Expanded(
                child: Row(
                  children: [
                    Sidebar(
                      directoryPath: _state.currentDirectoryPath,
                      files: _state.fileTree,
                      currentFilePath: _state.currentFilePath,
                      isDirty: _state.isDirty,
                      onFileSelected: _openFile,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: MilkdownEditor(
                          controller: _controller,
                          initialMarkdown: _welcomeMarkdown,
                          theme: _defaultTheme,
                          onReady: () => unawaited(_handleEditorReady()),
                          onChanged: _handleEditorChanged,
                          loadingBuilder: (BuildContext context) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (BuildContext context, Object error) {
                            return Center(
                              child: SelectableText(
                                error.toString(),
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBar(
                fileName: _displayFileName,
                isDirty: _state.isDirty,
                characterCount: _state.characterCount,
                lineCount: _state.lineCount,
                statusMessage: _statusMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Text(
            'Markdown Editor',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _state.isLoading ? null : _openFolder,
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('Open Folder'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isEditorReady && _state.isDirty
                ? () => unawaited(_saveCurrentDocument())
                : null,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save'),
          ),
          const SizedBox(width: 16),
          DropdownButton<MilkdownTheme>(
            value: _state.currentTheme,
            onChanged: (MilkdownTheme? value) {
              if (value == null) {
                return;
              }
              unawaited(_selectTheme(value));
            },
            items: _themeOptions
                .map(
                  (_ThemeOption option) => DropdownMenuItem<MilkdownTheme>(
                    value: option.theme,
                    child: Text(option.label),
                  ),
                )
                .toList(growable: false),
          ),
          const Spacer(),
          if (_state.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              _isEditorReady ? 'Ready' : 'Bootstrapping...',
              style: TextStyle(color: Colors.grey.shade700),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFFFEBEE),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _state.errorMessage!,
              style: const TextStyle(color: Color(0xFFB00020)),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _state = _state.copyWith(clearErrorMessage: true);
              });
            },
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFFB00020),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption(this.theme, this.label);

  final MilkdownTheme theme;
  final String label;
}

const List<_ThemeOption> _themeOptions = <_ThemeOption>[
  _ThemeOption(MilkdownTheme.frame, 'Frame'),
  _ThemeOption(MilkdownTheme.frameDark, 'Frame Dark'),
  _ThemeOption(MilkdownTheme.nord, 'Nord'),
  _ThemeOption(MilkdownTheme.nordDark, 'Nord Dark'),
];

String _themeLabel(MilkdownTheme theme) {
  for (final _ThemeOption option in _themeOptions) {
    if (option.theme == theme) {
      return option.label;
    }
  }
  return theme.value;
}

int _computeLineCount(String value) {
  if (value.isEmpty) {
    return 0;
  }
  return '\n'.allMatches(value).length + 1;
}
