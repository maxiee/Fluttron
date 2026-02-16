import 'package:fluttron_milkdown/fluttron_milkdown.dart';

class EditorState {
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
      fileTree: const <String>[],
    );
  }

  final String? currentFilePath;
  final String? currentDirectoryPath;
  final String currentContent;
  final String savedContent;
  final int characterCount;
  final int lineCount;
  final MilkdownTheme currentTheme;
  final bool isLoading;
  final String? errorMessage;
  final List<String> fileTree;

  bool get isDirty => currentContent != savedContent;

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
    List<String>? fileTree,
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
