import 'dart:async';

import 'package:fluttron_milkdown/fluttron_milkdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/editor_state.dart';

const MilkdownTheme _defaultTheme = MilkdownTheme.nord;
const String _welcomeMarkdown = '''
# Markdown Editor

Welcome to the Fluttron markdown editor example.

## What is included in this version

- Milkdown WYSIWYG editor integration
- Runtime theme switching
- Cmd/Ctrl + S shortcut for save state
- Status bar with file name, save state, char count, and line count

## Next

Open-folder file management and Host services (`file.*`, `dialog.*`, `clipboard.*`)
will be added in follow-up iterations.
''';

class MarkdownEditorApp extends StatefulWidget {
  const MarkdownEditorApp({super.key});

  @override
  State<MarkdownEditorApp> createState() => _MarkdownEditorAppState();
}

class _MarkdownEditorAppState extends State<MarkdownEditorApp> {
  final MilkdownController _controller = MilkdownController();

  late EditorState _state = EditorState.initial(
    initialContent: _welcomeMarkdown,
    currentTheme: _defaultTheme,
  );

  bool _isEditorReady = false;
  String _statusMessage = 'Initializing editor...';

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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: MilkdownEditor(
                    controller: _controller,
                    initialMarkdown: _welcomeMarkdown,
                    theme: _defaultTheme,
                    onReady: () => unawaited(_handleEditorReady()),
                    onChanged: _handleEditorChanged,
                    loadingBuilder: (BuildContext context) {
                      return const Center(child: CircularProgressIndicator());
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
      child: Text(
        _state.errorMessage!,
        style: const TextStyle(color: Color(0xFFB00020)),
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
