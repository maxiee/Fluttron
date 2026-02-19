import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/manifest_loader.dart';
import '../utils/ui_build_pipeline.dart';

/// `fluttron package -p <path> [--dmg]`
///
/// Steps:
/// 1. Run the UI build pipeline (same as `fluttron build`)
/// 2. Run `flutter build macos --release` in the host directory
/// 3. Copy the .app bundle to `<project>/dist/`
/// 4. (Optional) Create a .dmg disk image via `hdiutil` when `--dmg` is set
class PackageCommand extends Command<int> {
  @override
  String get name => 'package';

  @override
  String get description =>
      'Build and package the app for distribution. '
      'Produces a .app bundle in <project>/dist/. '
      'Use --dmg to also create a .dmg disk image.';

  PackageCommand() {
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Path to the Fluttron project root.',
      defaultsTo: '.',
      valueHelp: 'path',
    );
    argParser.addFlag(
      'dmg',
      help: 'Also create a .dmg disk image (macOS only, requires hdiutil).',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final projectPath = argResults?['project'] as String? ?? '.';
    final projectDir = Directory(p.normalize(projectPath));
    final createDmg = argResults?['dmg'] as bool? ?? false;
    final totalSteps = createDmg ? 4 : 3;

    try {
      final loaded = ManifestLoader.load(projectDir);
      final manifest = loaded.manifest;

      // Step 1: Build UI (flutter web + asset sync)
      stdout.writeln('[1/$totalSteps] Building UI...');
      final pipeline = UiBuildPipeline();
      final buildExitCode = await pipeline.build(
        projectDir: projectDir,
        manifestPath: loaded.manifestPath,
        manifest: manifest,
      );
      if (buildExitCode != 0) {
        stderr.writeln('UI build failed (exit code $buildExitCode).');
        return buildExitCode;
      }

      // Step 2: Locate host Flutter project
      final hostAssetsDir = Directory(
        p.join(projectDir.path, manifest.entry.hostAssetPath),
      );
      final hostProjectDir = _findFlutterProjectRoot(hostAssetsDir);
      if (hostProjectDir == null) {
        stderr.writeln(
          'Unable to locate host Flutter project (pubspec.yaml not found).',
        );
        return 2;
      }

      stdout.writeln('[2/$totalSteps] Building macOS release bundle...');
      stdout.writeln('      Host: ${p.normalize(hostProjectDir.path)}');
      final flutterExitCode = await _runFlutterBuildMacos(hostProjectDir);
      if (flutterExitCode != 0) {
        stderr.writeln(
          'flutter build macos failed (exit code $flutterExitCode).',
        );
        return flutterExitCode;
      }

      // Step 3: Locate the built .app bundle
      final appBundleDir = _findAppBundle(hostProjectDir);
      if (appBundleDir == null) {
        stderr.writeln(
          'No .app bundle found in '
          '${p.normalize(hostProjectDir.path)}/build/macos/Build/Products/Release.',
        );
        return 2;
      }

      // Step 3: Copy .app to <project>/dist/
      stdout.writeln('[3/$totalSteps] Copying .app to dist/...');
      final distDir = Directory(p.join(projectDir.path, 'dist'));
      distDir.createSync(recursive: true);

      final destApp = Directory(
        p.join(distDir.path, p.basename(appBundleDir.path)),
      );
      if (destApp.existsSync()) {
        destApp.deleteSync(recursive: true);
      }

      final copyResult = await _copyAppBundle(appBundleDir, destApp);
      if (copyResult != 0) {
        stderr.writeln('Failed to copy .app bundle (exit code $copyResult).');
        return copyResult;
      }

      final sizeBytes = _directorySizeBytes(destApp);
      final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);

      stdout.writeln('');
      stdout.writeln('  .app → ${p.normalize(destApp.path)}');
      stdout.writeln('  Size: $sizeMb MB');

      // Step 4 (optional): Create .dmg
      if (createDmg) {
        stdout.writeln('');
        stdout.writeln('[4/$totalSteps] Creating DMG...');

        final appName = p.basenameWithoutExtension(destApp.path);
        final dmgFile = File(p.join(distDir.path, '$appName.dmg'));
        if (dmgFile.existsSync()) {
          dmgFile.deleteSync();
        }

        final dmgExitCode = await _runHdiutil(
          volname: appName,
          srcfolder: destApp.path,
          output: dmgFile.path,
        );
        if (dmgExitCode != 0) {
          stderr.writeln('hdiutil failed (exit code $dmgExitCode).');
          return dmgExitCode;
        }

        final dmgSizeBytes = dmgFile.lengthSync();
        final dmgSizeMb = (dmgSizeBytes / (1024 * 1024)).toStringAsFixed(1);

        stdout.writeln('  .dmg → ${p.normalize(dmgFile.path)}');
        stdout.writeln('  Size: $dmgSizeMb MB');
      }

      stdout.writeln('');
      stdout.writeln('Package complete!');
      return 0;
    } on ManifestException catch (error) {
      stderr.writeln(error);
      return 2;
    } on FileSystemException catch (error) {
      stderr.writeln(error.message);
      return 2;
    }
  }

  Future<int> _runFlutterBuildMacos(Directory hostDir) async {
    final process = await Process.start(
      'flutter',
      ['build', 'macos', '--release'],
      workingDirectory: hostDir.path,
      runInShell: true,
    );
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);
    return process.exitCode;
  }

  /// Wraps `hdiutil create` to produce a compressed .dmg from an .app bundle.
  Future<int> _runHdiutil({
    required String volname,
    required String srcfolder,
    required String output,
  }) async {
    final process = await Process.start(
      'hdiutil',
      [
        'create',
        '-volname', volname,
        '-srcfolder', srcfolder,
        '-ov',
        '-format', 'UDZO',
        output,
      ],
      runInShell: false,
    );
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);
    return process.exitCode;
  }

  /// Uses `ditto` to preserve symlinks, resource forks, and extended attributes
  /// that are common inside macOS .app bundles.
  Future<int> _copyAppBundle(Directory source, Directory dest) async {
    final process = await Process.start(
      'ditto',
      [source.path, dest.path],
      runInShell: false,
    );
    await stderr.addStream(process.stderr);
    return process.exitCode;
  }

  Directory? _findAppBundle(Directory hostProjectDir) {
    final releaseDir = Directory(
      p.join(
        hostProjectDir.path,
        'build',
        'macos',
        'Build',
        'Products',
        'Release',
      ),
    );
    if (!releaseDir.existsSync()) {
      return null;
    }
    for (final entity in releaseDir.listSync()) {
      if (entity is Directory && entity.path.endsWith('.app')) {
        return entity;
      }
    }
    return null;
  }

  Directory? _findFlutterProjectRoot(Directory startDir) {
    var current = startDir;
    for (var i = 0; i < 5; i++) {
      final pubspec = File(p.join(current.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        return current;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }
    return null;
  }

  int _directorySizeBytes(Directory dir) {
    var total = 0;
    try {
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += entity.lengthSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }
}
