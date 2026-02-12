import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Handles copying and transforming web_package templates with variable substitution.
class WebPackageCopier {
  /// Copies web_package template with variable substitution.
  ///
  /// [packageName] is the user-specified package name (e.g., "my_editor").
  /// [sourceDir] is the template directory (templates/web_package).
  /// [destinationDir] is the target directory for the new package.
  Future<void> copyAndTransform({
    required String packageName,
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
    final snakeCase = _toSnakeCase(packageName);
    final pascalCase = _toPascalCase(packageName);
    final camelCase = _toCamelCase(packageName);
    final kebabCase = _toKebabCase(packageName);
    final libraryName = snakeCase;

    // Template placeholders
    const templatePackageName = 'fluttron_web_package_template';
    const templateSnakeCase = 'template_package';
    const templatePascalCase = 'TemplatePackage';
    const templateCamelCase = 'templatePackage';
    const templateKebabCase = 'template-package';

    await for (final entity in sourceDir.list(followLinks: false)) {
      await _copyAndTransformEntity(
        entity: entity,
        sourceRoot: sourceDir,
        destinationRoot: destinationDir,
        substitutions: {
          templatePackageName: libraryName,
          templateSnakeCase: snakeCase,
          templatePascalCase: pascalCase,
          templateCamelCase: camelCase,
          templateKebabCase: kebabCase,
        },
        originalPackageName: templatePackageName,
        newPackageName: libraryName,
      );
    }
  }

  Future<void> _copyAndTransformEntity({
    required FileSystemEntity entity,
    required Directory sourceRoot,
    required Directory destinationRoot,
    required Map<String, String> substitutions,
    required String originalPackageName,
    required String newPackageName,
  }) async {
    final relativePath = p.relative(entity.path, from: sourceRoot.path);

    // Skip directories that shouldn't be copied
    if (entity is Directory) {
      final dirName = p.basename(entity.path);
      if (_shouldSkipDirectory(dirName)) {
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
          originalPackageName: originalPackageName,
          newPackageName: newPackageName,
        );
      }
      return;
    }

    if (entity is File) {
      final destinationFile = File(destinationPath);
      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }

      // Check if file is binary or should be copied as-is
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
        content = _updatePubspecName(content, newPackageName);
      }

      // Special handling for fluttron_web_package.json
      if (entity.path.endsWith('fluttron_web_package.json')) {
        content = _updateWebPackageManifest(content, substitutions);
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

  String _updatePubspecName(String content, String newPackageName) {
    // Replace the name field in pubspec.yaml
    final lines = content.split('\n');
    final updatedLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('name:')) {
        updatedLines.add('name: $newPackageName');
      } else {
        updatedLines.add(line);
      }
    }

    return updatedLines.join('\n');
  }

  String _updateWebPackageManifest(
    String content,
    Map<String, String> substitutions,
  ) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Update viewFactories
      if (json['viewFactories'] is List) {
        final factories = json['viewFactories'] as List;
        for (var i = 0; i < factories.length; i++) {
          final factory = factories[i] as Map<String, dynamic>;

          // Update type field
          if (factory['type'] is String) {
            var type = factory['type'] as String;
            substitutions.forEach((original, replacement) {
              type = type.replaceAll(original, replacement);
            });
            factory['type'] = type;
          }

          // Update jsFactoryName field
          if (factory['jsFactoryName'] is String) {
            var jsFactoryName = factory['jsFactoryName'] as String;
            substitutions.forEach((original, replacement) {
              jsFactoryName = jsFactoryName.replaceAll(original, replacement);
            });
            factory['jsFactoryName'] = jsFactoryName;
          }
        }
      }

      // Update events
      if (json['events'] is List) {
        final events = json['events'] as List;
        for (var i = 0; i < events.length; i++) {
          final event = events[i] as Map<String, dynamic>;

          if (event['name'] is String) {
            var name = event['name'] as String;
            substitutions.forEach((original, replacement) {
              name = name.replaceAll(original, replacement);
            });
            event['name'] = name;
          }
        }
      }

      const encoder = JsonEncoder.withIndent('  ');
      return '${encoder.convert(json)}\n';
    } catch (e) {
      // If JSON parsing fails, return original content
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
      return 'web_package';
    }
    if (RegExp(r'^[0-9]').hasMatch(result)) {
      return 'pkg_$result';
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

  /// Converts a string to kebab-case.
  String _toKebabCase(String input) {
    // Convert to snake_case first, then replace underscores with hyphens
    return _toSnakeCase(input).replaceAll('_', '-');
  }
}
