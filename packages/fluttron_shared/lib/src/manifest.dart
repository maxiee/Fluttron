import 'package:json_annotation/json_annotation.dart';

part 'manifest.g.dart';

@JsonSerializable()
class FluttronManifest {
  // App name
  final String appName;

  // App unique identifier (e.g., com.example.app)
  final String appId;

  // Version
  final String version;

  // Entry point (relative path to Flutter Web build output, defaults to index.html)
  final String entryPoint;

  // Window configuration (desktop priority)
  final WindowConfig window;

  FluttronManifest({
    required this.appName,
    required this.appId,
    required this.version,
    this.entryPoint = 'index.html',
    this.window = const WindowConfig(),
  });

  factory FluttronManifest.fromJson(Map<String, dynamic> json) =>
      _$FluttronManifestFromJson(json);
  Map<String, dynamic> toJson() => _$FluttronManifestToJson(this);
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
