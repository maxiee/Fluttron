import 'package:fluttron_ui/fluttron_ui.dart';

class MilkdownChangeEvent {
  const MilkdownChangeEvent({
    required this.viewId,
    required this.markdown,
    required this.characterCount,
    required this.lineCount,
    required this.updatedAt,
  });

  factory MilkdownChangeEvent.fromMap(Map<String, dynamic> map) {
    return MilkdownChangeEvent(
      viewId: (map['viewId'] as num?)?.toInt() ?? 0,
      markdown: map['markdown']?.toString() ?? '',
      characterCount: (map['characterCount'] as num?)?.toInt() ?? 0,
      lineCount: (map['lineCount'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }

  final int viewId;
  final String markdown;
  final int characterCount;
  final int lineCount;
  final String updatedAt;

  @override
  String toString() =>
      'MilkdownChangeEvent(viewId: $viewId, characterCount: $characterCount, lineCount: $lineCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilkdownChangeEvent &&
          runtimeType == other.runtimeType &&
          viewId == other.viewId &&
          markdown == other.markdown &&
          characterCount == other.characterCount &&
          lineCount == other.lineCount &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(viewId, markdown, characterCount, lineCount, updatedAt);
}

Stream<MilkdownChangeEvent> milkdownEditorChanges({int? viewId}) {
  final stream = FluttronEventBridge().on('fluttron.milkdown.editor.change');
  final mapped = stream.map(MilkdownChangeEvent.fromMap);
  if (viewId == null) {
    return mapped;
  }
  return mapped.where((event) => event.viewId == viewId);
}

Stream<int> milkdownEditorReady({int? viewId}) {
  final stream = FluttronEventBridge().on('fluttron.milkdown.editor.ready');
  final mapped = stream.map((detail) {
    final rawViewId = detail['viewId'];
    return rawViewId is num ? rawViewId.toInt() : 0;
  });
  if (viewId == null) {
    return mapped;
  }
  return mapped.where((id) => id == viewId);
}

Stream<int> milkdownEditorFocus({int? viewId}) {
  final stream = FluttronEventBridge().on('fluttron.milkdown.editor.focus');
  final mapped = stream.map((detail) {
    final rawViewId = detail['viewId'];
    return rawViewId is num ? rawViewId.toInt() : 0;
  });
  if (viewId == null) {
    return mapped;
  }
  return mapped.where((id) => id == viewId);
}

Stream<int> milkdownEditorBlur({int? viewId}) {
  final stream = FluttronEventBridge().on('fluttron.milkdown.editor.blur');
  final mapped = stream.map((detail) {
    final rawViewId = detail['viewId'];
    return rawViewId is num ? rawViewId.toInt() : 0;
  });
  if (viewId == null) {
    return mapped;
  }
  return mapped.where((id) => id == viewId);
}
