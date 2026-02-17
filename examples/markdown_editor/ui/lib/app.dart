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

const MilkdownTheme _defaultTheme = MilkdownTheme.nord;
const String _welcomeMarkdown = '''
# Markdown Editor

Welcome to the Fluttron markdown editor example.

## Getting Started

Click **Open Folder** to select a directory containing markdown files.

## Features

- File tree sidebar (`.md` files only)
- Milkdown WYSIWYG editor
- Runtime theme switching
- Save with `Cmd/Ctrl + S`

## Next

More features will be added in upcoming versions:
- Save files to disk
- Create new files
- Theme persistence
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
    // v0055 will implement actual file loading
    // For now, just show a status message
    setState(() {
      _statusMessage = 'Opening ${file.name}... (file loading in v0055)';
    });
  }

  Future<void> _saveInMemory() async {
    if (!_isEditorReady) {
      return;
    }

    try {
      final String content = await _controller.getContent();
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
        _statusMessage = 'Saved';
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
    unawaited(_saveInMemory());
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
              _buildStatusBar(),
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
                ? () => unawaited(_saveInMemory())
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

  Widget _buildStatusBar() {
    return Container(
      height: 36,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          _StatusSegment(text: _displayFileName),
          _StatusSegment(text: _state.isDirty ? 'Unsaved' : 'Saved'),
          _StatusSegment(text: '${_state.characterCount} chars'),
          _StatusSegment(text: '${_state.lineCount} lines'),
          const Spacer(),
          _StatusSegment(text: _statusMessage),
        ],
      ),
    );
  }
}

class _StatusSegment extends StatelessWidget {
  const _StatusSegment({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12),
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
