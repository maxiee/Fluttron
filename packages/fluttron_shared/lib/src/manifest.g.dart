// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FluttronManifest _$FluttronManifestFromJson(Map<String, dynamic> json) =>
    FluttronManifest(
      name: json['name'] as String,
      version: json['version'] as String,
      entry: EntryConfig.fromJson(json['entry'] as Map<String, dynamic>),
      window: json['window'] == null
          ? const WindowConfig()
          : WindowConfig.fromJson(json['window'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FluttronManifestToJson(FluttronManifest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'entry': instance.entry.toJson(),
      'window': instance.window.toJson(),
    };

EntryConfig _$EntryConfigFromJson(Map<String, dynamic> json) => EntryConfig(
  uiProjectPath: json['uiProjectPath'] as String,
  hostAssetPath: json['hostAssetPath'] as String,
  index: json['index'] as String? ?? 'index.html',
);

Map<String, dynamic> _$EntryConfigToJson(EntryConfig instance) =>
    <String, dynamic>{
      'uiProjectPath': instance.uiProjectPath,
      'hostAssetPath': instance.hostAssetPath,
      'index': instance.index,
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
