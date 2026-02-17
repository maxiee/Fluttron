import 'package:fluttron_milkdown/fluttron_milkdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_editor_ui/models/editor_state.dart';

void main() {
  test('initial state starts clean with computed counters', () {
    const String content = '# Title\n\nBody';

    final EditorState state = EditorState.initial(
      initialContent: content,
      currentTheme: MilkdownTheme.nord,
    );

    expect(state.currentContent, content);
    expect(state.savedContent, content);
    expect(state.characterCount, content.length);
    expect(state.lineCount, 3);
    expect(state.isDirty, isFalse);
    expect(state.currentTheme, MilkdownTheme.nord);
  });

  test('copyWith updates dirty flag from current and saved content', () {
    final EditorState state = EditorState.initial(initialContent: 'a');

    final EditorState dirty = state.copyWith(
      currentContent: 'ab',
      characterCount: 2,
      lineCount: 1,
    );
    expect(dirty.isDirty, isTrue);

    final EditorState saved = dirty.copyWith(savedContent: 'ab');
    expect(saved.isDirty, isFalse);
  });

  test('copyWith can clear existing error message', () {
    final EditorState withError = EditorState.initial(
      initialContent: '',
    ).copyWith(errorMessage: 'failed');

    final EditorState cleared = withError.copyWith(clearErrorMessage: true);
    expect(cleared.errorMessage, isNull);
  });

  test('copyWith can explicitly clear nullable path fields', () {
    final EditorState seeded = EditorState.initial(initialContent: '# Doc')
        .copyWith(
          currentDirectoryPath: '/tmp/docs',
          currentFilePath: '/tmp/docs/readme.md',
        );

    final EditorState cleared = seeded.copyWith(
      currentDirectoryPath: null,
      currentFilePath: null,
    );

    expect(cleared.currentDirectoryPath, isNull);
    expect(cleared.currentFilePath, isNull);
  });
}
