import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Handles copying and transforming host_service templates with variable substitution.
///
/// The host_service template contains two sub-packages:
/// - `{name}_host/` - Host-side service implementation
/// - `{name}_client/` - UI-side client stub
class HostServiceCopier {
  /// Template placeholder strings
  static const _templateSnakeCase = 'template_service';
  static const _templatePascalCase = 'TemplateService';
  static const _templateCamelCase = 'templateService';

  /// Copies host_service template with variable substitution.
  ///
  /// [serviceName] is the user-specified service name (e.g., "my_notification_service").
  /// [sourceDir] is the template directory (templates/host_service).
  /// [destinationDir] is the target directory for the new service.
  Future<void> copyAndTransform({
    required String serviceName,
    required Directory sourceDir,
    required Directory destinationDir,
  }) async {
    if (!sourceDir.existsSync()) {
      throw FileSystemException(
        'Template directory not found.',
        sourceDir.path,
      );
    }

    if (!destinationDir.existsSync()) {
      destinationDir.createSync(recursive: true);
    }

    // Generate naming conventions
    final snakeCase = normalizeServiceName(serviceName);
    final pascalCase = _toPascalCase(snakeCase);
    final camelCase = _toCamelCase(snakeCase);

    // Build substitution map
    final substitutions = <String, String>{
      _templateSnakeCase: snakeCase,
      _templatePascalCase: pascalCase,
      _templateCamelCase: camelCase,
    };

    await for (final entity in sourceDir.list(followLinks: false)) {
      await _copyAndTransformEntity(
        entity: entity,
        sourceRoot: sourceDir,
        destinationRoot: destinationDir,
        substitutions: substitutions,
      );
    }
  }

  /// Converts user input to a valid snake_case service name.
  String normalizeServiceName(String input) => _toSnakeCase(input);

  Future<void> _copyAndTransformEntity({
    required FileSystemEntity entity,
    required Directory sourceRoot,
    required Directory destinationRoot,
    required Map<String, String> substitutions,
  }) async {
    final relativePath = p.relative(entity.path, from: sourceRoot.path);

    // Skip directories that shouldn't be copied
    if (entity is Directory) {
      final dirName = p.basename(entity.path);
      if (_shouldSkipDirectory(dirName)) {
        return;
      }
    }

    if (entity is File) {
      final fileName = p.basename(entity.path);
      if (_shouldSkipFile(fileName)) {
        return;
      }
    }

    // Transform file/directory names
    var destinationRelativePath = relativePath;
    substitutions.forEach((original, replacement) {
      destinationRelativePath = destinationRelativePath.replaceAll(
        original,
        replacement,
      );
    });

    final destinationPath = p.join(
      destinationRoot.path,
      destinationRelativePath,
    );

    if (entity is Directory) {
      final destinationDir = Directory(destinationPath);
      if (!destinationDir.existsSync()) {
        destinationDir.createSync(recursive: true);
      }
      await for (final child in entity.list(followLinks: false)) {
        await _copyAndTransformEntity(
          entity: child,
          sourceRoot: sourceRoot,
          destinationRoot: destinationRoot,
          substitutions: substitutions,
        );
      }
      return;
    }

    if (entity is File) {
      final destinationFile = File(destinationPath);
      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }

      // Check if file should be copied as binary
      if (_shouldCopyAsBinary(entity.path)) {
        await entity.copy(destinationFile.path);
        return;
      }

      // Read original content
      String content;
      try {
        content = await entity.readAsString();
      } catch (e) {
        // If reading as string fails, copy as binary
        await entity.copy(destinationFile.path);
        return;
      }

      // Apply text substitutions
      substitutions.forEach((original, replacement) {
        content = content.replaceAll(original, replacement);
      });

      // Special handling for pubspec.yaml - update name field
      if (entity.path.endsWith('pubspec.yaml')) {
        content = _updatePubspecName(content, substitutions);
      }

      // Special handling for fluttron_host_service.json
      if (entity.path.endsWith('fluttron_host_service.json')) {
        content = _updateHostServiceManifest(content, substitutions);
      }

      await destinationFile.writeAsString(content);
      return;
    }

    if (entity is Link) {
      final target = await entity.target();
      var transformedTarget = target;
      substitutions.forEach((original, replacement) {
        transformedTarget = transformedTarget.replaceAll(original, replacement);
      });
      final destinationLink = Link(destinationPath);
      await destinationLink.create(transformedTarget, recursive: true);
      return;
    }
  }

  /// Returns true if the directory should be skipped during copy.
  bool _shouldSkipDirectory(String dirName) {
    const skipDirs = {'node_modules', '.dart_tool', 'build', '.idea'};
    return skipDirs.contains(dirName);
  }

  /// Returns true if the file should be skipped during copy.
  bool _shouldSkipFile(String fileName) {
    const skipFiles = {
      '.flutter-plugins',
      '.flutter-plugins-dependencies',
      '.DS_Store',
      'pubspec.lock',
    };
    return skipFiles.contains(fileName);
  }

  /// Returns true if the file should be copied as binary (no text transformation).
  bool _shouldCopyAsBinary(String filePath) {
    // Skip sourcemap files
    if (filePath.endsWith('.map')) {
      return true;
    }

    // Skip binary file extensions
    const binaryExtensions = {
      '.ico',
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.woff',
      '.woff2',
      '.ttf',
      '.eot',
      '.otf',
    };

    final ext = p.extension(filePath).toLowerCase();
    return binaryExtensions.contains(ext);
  }

  /// Updates the name field in pubspec.yaml with proper suffix.
  ///
  /// For host package: `{serviceName}_host`
  /// For client package: `{serviceName}_client`
  String _updatePubspecName(String content, Map<String, String> substitutions) {
    // Replace the name field in pubspec.yaml
    final lines = content.split('\n');
    final updatedLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('name:')) {
        // Extract the current name value to determine if it's host or client
        final currentName = line.substring(5).trim();

        // Determine the suffix based on template name
        String newName;
        if (currentName == 'template_service_host') {
          newName = '${substitutions[_templateSnakeCase]}_host';
        } else if (currentName == 'template_service_client') {
          newName = '${substitutions[_templateSnakeCase]}_client';
        } else {
          // Fallback: apply substitutions
          newName = currentName;
          substitutions.forEach((original, replacement) {
            newName = newName.replaceAll(original, replacement);
          });
        }
        updatedLines.add('name: $newName');
      } else {
        updatedLines.add(line);
      }
    }

    return updatedLines.join('\n');
  }

  /// Updates the host service manifest with transformed values.
  String _updateHostServiceManifest(
    String content,
    Map<String, String> substitutions,
  ) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Update name field
      if (json['name'] is String) {
        json['name'] = substitutions[_templateSnakeCase];
      }

      // Update namespace field
      if (json['namespace'] is String) {
        json['namespace'] = substitutions[_templateSnakeCase];
      }

      const encoder = JsonEncoder.withIndent('  ');
      return '${encoder.convert(json)}\n';
    } catch (e) {
      // If JSON parsing fails, return original content with substitutions
      return content;
    }
  }

  /// Converts a string to snake_case.
  String _toSnakeCase(String input) {
    final normalizedInput = input.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9]+'),
      '_',
    );

    final buffer = StringBuffer();
    for (var i = 0; i < normalizedInput.length; i++) {
      final char = normalizedInput[i];
      if (char.toUpperCase() == char && char.toLowerCase() != char) {
        final hasPrevious = i > 0;
        final previousChar = hasPrevious ? normalizedInput[i - 1] : '';
        if (hasPrevious && previousChar != '_') {
          buffer.write('_');
        }
        buffer.write(char.toLowerCase());
      } else {
        buffer.write(char.toLowerCase());
      }
    }

    var result = buffer.toString();
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceFirst(RegExp(r'^_+'), '');
    result = result.replaceFirst(RegExp(r'_+$'), '');

    if (result.isEmpty) {
      return 'custom_service';
    }
    if (RegExp(r'^[0-9]').hasMatch(result)) {
      return 'svc_$result';
    }
    return result;
  }

  /// Converts a string to PascalCase.
  String _toPascalCase(String input) {
    // Handle snake_case
    final parts = input.split('_');
    return parts
        .map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join('');
  }

  /// Converts a string to camelCase.
  String _toCamelCase(String input) {
    final pascal = _toPascalCase(input);
    if (pascal.isEmpty) return '';
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}
