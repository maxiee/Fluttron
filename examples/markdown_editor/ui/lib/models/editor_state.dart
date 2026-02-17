import 'package:fluttron_milkdown/fluttron_milkdown.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

/// Represents the state of the Markdown editor.
class EditorState {
  /// Creates an EditorState with the given values.
  const EditorState({
    this.currentFilePath,
    this.currentDirectoryPath,
    required this.currentContent,
    required this.savedContent,
    required this.characterCount,
    required this.lineCount,
    required this.currentTheme,
    required this.fileTree,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Creates an initial EditorState with the given content.
  factory EditorState.initial({
    required String initialContent,
    MilkdownTheme currentTheme = MilkdownTheme.frame,
  }) {
    return EditorState(
      currentContent: initialContent,
      savedContent: initialContent,
      characterCount: initialContent.length,
      lineCount: _computeLineCount(initialContent),
      currentTheme: currentTheme,
      fileTree: const <FileEntry>[],
    );
  }

  /// The path to the currently open file, or null if no file is open.
  final String? currentFilePath;

  /// The path to the currently open directory, or null if no folder is open.
  final String? currentDirectoryPath;

  /// The current markdown content in the editor.
  final String currentContent;

  /// The last saved version of the content (for dirty checking).
  final String savedContent;

  /// The character count of the current content.
  final int characterCount;

  /// The line count of the current content.
  final int lineCount;

  /// The currently selected theme.
  final MilkdownTheme currentTheme;

  /// Whether a file operation is in progress.
  final bool isLoading;

  /// The current error message, or null if no error.
  final String? errorMessage;

  /// The list of markdown files in the current directory.
  final List<FileEntry> fileTree;

  /// Whether the current content has unsaved changes.
  bool get isDirty => currentContent != savedContent;

  /// Creates a copy of this state with the given fields replaced.
  EditorState copyWith({
    String? currentFilePath,
    String? currentDirectoryPath,
    String? currentContent,
    String? savedContent,
    int? characterCount,
    int? lineCount,
    MilkdownTheme? currentTheme,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<FileEntry>? fileTree,
  }) {
    return EditorState(
      currentFilePath: currentFilePath ?? this.currentFilePath,
      currentDirectoryPath: currentDirectoryPath ?? this.currentDirectoryPath,
      currentContent: currentContent ?? this.currentContent,
      savedContent: savedContent ?? this.savedContent,
      characterCount: characterCount ?? this.characterCount,
      lineCount: lineCount ?? this.lineCount,
      currentTheme: currentTheme ?? this.currentTheme,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      fileTree: fileTree ?? this.fileTree,
    );
  }

  static int _computeLineCount(String value) {
    if (value.isEmpty) {
      return 0;
    }
    return '\n'.allMatches(value).length + 1;
  }
}
