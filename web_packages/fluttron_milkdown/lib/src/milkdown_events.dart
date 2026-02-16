import 'package:fluttron_ui/fluttron_ui.dart';

final FluttronEventBridge _sharedMilkdownEventBridge = FluttronEventBridge();

class MilkdownChangeEvent {
  const MilkdownChangeEvent({
    required this.viewId,
    required this.markdown,
    required this.characterCount,
    required this.lineCount,
    required this.updatedAt,
    this.instanceToken,
  });

  factory MilkdownChangeEvent.fromMap(Map<String, dynamic> map) {
    return MilkdownChangeEvent(
      viewId: (map['viewId'] as num?)?.toInt() ?? 0,
      markdown: map['markdown']?.toString() ?? '',
      characterCount: (map['characterCount'] as num?)?.toInt() ?? 0,
      lineCount: (map['lineCount'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt']?.toString() ?? '',
      instanceToken: map['instanceToken']?.toString(),
    );
  }

  final int viewId;
  final String markdown;
  final int characterCount;
  final int lineCount;
  final String updatedAt;
  final String? instanceToken;

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
          updatedAt == other.updatedAt &&
          instanceToken == other.instanceToken;

  @override
  int get hashCode => Object.hash(
    viewId,
    markdown,
    characterCount,
    lineCount,
    updatedAt,
    instanceToken,
  );
}

FluttronEventBridge _resolveEventBridge(FluttronEventBridge? eventBridge) {
  return eventBridge ?? _sharedMilkdownEventBridge;
}

bool _matchesInstanceToken(Map<String, dynamic> detail, String? instanceToken) {
  if (instanceToken == null) {
    return true;
  }
  return detail['instanceToken']?.toString() == instanceToken;
}

int _extractViewId(Map<String, dynamic> detail) {
  final rawViewId = detail['viewId'];
  if (rawViewId is num) {
    return rawViewId.toInt();
  }
  return 0;
}

Stream<Map<String, dynamic>> _listenMilkdownEvent({
  required String eventName,
  int? viewId,
  String? instanceToken,
  FluttronEventBridge? eventBridge,
}) {
  final bridge = _resolveEventBridge(eventBridge);
  final stream = bridge.on(eventName);
  return stream.where((detail) {
    if (!_matchesInstanceToken(detail, instanceToken)) {
      return false;
    }
    if (viewId == null) {
      return true;
    }
    return _extractViewId(detail) == viewId;
  });
}

Stream<MilkdownChangeEvent> milkdownEditorChanges({
  int? viewId,
  String? instanceToken,
  FluttronEventBridge? eventBridge,
}) {
  return _listenMilkdownEvent(
    eventName: 'fluttron.milkdown.editor.change',
    viewId: viewId,
    instanceToken: instanceToken,
    eventBridge: eventBridge,
  ).map(MilkdownChangeEvent.fromMap);
}

Stream<int> milkdownEditorReady({
  int? viewId,
  String? instanceToken,
  FluttronEventBridge? eventBridge,
}) {
  return _listenMilkdownEvent(
    eventName: 'fluttron.milkdown.editor.ready',
    viewId: viewId,
    instanceToken: instanceToken,
    eventBridge: eventBridge,
  ).map(_extractViewId);
}

Stream<int> milkdownEditorFocus({
  int? viewId,
  String? instanceToken,
  FluttronEventBridge? eventBridge,
}) {
  return _listenMilkdownEvent(
    eventName: 'fluttron.milkdown.editor.focus',
    viewId: viewId,
    instanceToken: instanceToken,
    eventBridge: eventBridge,
  ).map(_extractViewId);
}

Stream<int> milkdownEditorBlur({
  int? viewId,
  String? instanceToken,
  FluttronEventBridge? eventBridge,
}) {
  return _listenMilkdownEvent(
    eventName: 'fluttron.milkdown.editor.blur',
    viewId: viewId,
    instanceToken: instanceToken,
    eventBridge: eventBridge,
  ).map(_extractViewId);
}
