import 'package:json_annotation/json_annotation.dart';

part 'manifest.g.dart';

@JsonSerializable(explicitToJson: true)
class FluttronManifest {
  final String name;
  final String version;
  final EntryConfig entry;
  final WindowConfig window;

  const FluttronManifest({
    required this.name,
    required this.version,
    required this.entry,
    this.window = const WindowConfig(),
  });

  factory FluttronManifest.fromJson(Map<String, dynamic> json) =>
      _$FluttronManifestFromJson(json);
  Map<String, dynamic> toJson() => _$FluttronManifestToJson(this);
}

@JsonSerializable()
class EntryConfig {
  final String uiProjectPath;
  final String hostAssetPath;
  final String index;

  const EntryConfig({
    required this.uiProjectPath,
    required this.hostAssetPath,
    this.index = 'index.html',
  });

  factory EntryConfig.fromJson(Map<String, dynamic> json) =>
      _$EntryConfigFromJson(json);
  Map<String, dynamic> toJson() => _$EntryConfigToJson(this);
}

@JsonSerializable()
class WindowConfig {
  final String title;
  final double width;
  final double height;
  final bool resizable;

  const WindowConfig({
    this.title = 'Fluttron App',
    this.width = 1280,
    this.height = 800,
    this.resizable = true,
  });

  factory WindowConfig.fromJson(Map<String, dynamic> json) =>
      _$WindowConfigFromJson(json);
  Map<String, dynamic> toJson() => _$WindowConfigToJson(this);
}
