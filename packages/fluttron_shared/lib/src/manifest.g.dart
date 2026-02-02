// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FluttronManifest _$FluttronManifestFromJson(Map<String, dynamic> json) =>
    FluttronManifest(
      appName: json['appName'] as String,
      appId: json['appId'] as String,
      version: json['version'] as String,
      entryPoint: json['entryPoint'] as String? ?? 'index.html',
      window: json['window'] == null
          ? const WindowConfig()
          : WindowConfig.fromJson(json['window'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FluttronManifestToJson(FluttronManifest instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'appId': instance.appId,
      'version': instance.version,
      'entryPoint': instance.entryPoint,
      'window': instance.window,
    };

WindowConfig _$WindowConfigFromJson(Map<String, dynamic> json) => WindowConfig(
  title: json['title'] as String? ?? 'Fluttron App',
  width: (json['width'] as num?)?.toDouble() ?? 1280,
  height: (json['height'] as num?)?.toDouble() ?? 800,
  resizable: json['resizable'] as bool? ?? true,
);

Map<String, dynamic> _$WindowConfigToJson(WindowConfig instance) =>
    <String, dynamic>{
      'title': instance.title,
      'width': instance.width,
      'height': instance.height,
      'resizable': instance.resizable,
    };
