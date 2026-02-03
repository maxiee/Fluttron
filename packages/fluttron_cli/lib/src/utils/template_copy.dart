import 'dart:io';

import 'package:path/path.dart' as p;

class TemplateCopier {
  Future<void> copyContents({
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

    await for (final entity in sourceDir.list(followLinks: false)) {
      await _copyEntity(
        entity: entity,
        sourceRoot: sourceDir,
        destinationRoot: destinationDir,
      );
    }
  }

  Future<void> _copyEntity({
    required FileSystemEntity entity,
    required Directory sourceRoot,
    required Directory destinationRoot,
  }) async {
    final relativePath = p.relative(entity.path, from: sourceRoot.path);
    final destinationPath = p.join(destinationRoot.path, relativePath);

    if (entity is Directory) {
      final destinationDir = Directory(destinationPath);
      if (!destinationDir.existsSync()) {
        destinationDir.createSync(recursive: true);
      }
      await for (final child in entity.list(followLinks: false)) {
        await _copyEntity(
          entity: child,
          sourceRoot: sourceRoot,
          destinationRoot: destinationRoot,
        );
      }
      return;
    }

    if (entity is File) {
      final destinationFile = File(destinationPath);
      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }
      await entity.copy(destinationFile.path);
      return;
    }

    if (entity is Link) {
      final target = await entity.target();
      final destinationLink = Link(destinationPath);
      await destinationLink.create(target, recursive: true);
      return;
    }
  }
}
