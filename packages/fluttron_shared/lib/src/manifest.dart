import 'package:json_annotation/json_annotation.dart';

part 'manifest.g.dart';

@JsonSerializable()
class FluttronManifest {
  // 应用名称
  final String appName;

  // 应用唯一标识 (e.g., com.example.app)
  final String appId;

  // 版本号
  final String version;

  // 入口文件 (Flutter Web 编译产物的相对路径，默认 index.html)
  final String entryPoint;

  // 窗口配置 (桌面端优先)
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
