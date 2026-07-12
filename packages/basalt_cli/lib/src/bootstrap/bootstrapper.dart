import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'backend_resolver.dart';
import 'entrypoint_generator.dart';

/// The `basalt` executable's first stage: resolves the backend package,
/// (re)generates `.dart_tool/basalt/entrypoint.dart` when stale, and runs it
/// in a child Dart process with the original arguments (the same model
/// `build_runner` uses — Dart has no dynamic code loading, so plugging in a
/// backend the CLI doesn't depend on requires generated code).
final class Bootstrapper {
  const Bootstrapper();

  /// Bumped when the generated entrypoint's shape changes, so existing
  /// projects regenerate on upgrade.
  static const _formatVersion = 1;

  /// Suggested packages per URL scheme, used to make the missing-backend
  /// error actionable.
  static const _knownBackends = {
    'basalt_sqlite': 'SQLite',
    'basalt_postgres': 'Postgres',
  };

  Future<int> run(List<String> args, {Map<String, String>? environment}) async {
    final backend = const BackendResolver().resolve(
      _configPath(args),
      environment: environment,
    );

    final packageConfig = _findPackageConfig(Directory.current);
    if (packageConfig == null) {
      throw StateError(
        'No .dart_tool/package_config.json found — run `dart pub get` '
        '(or `flutter pub get`) in the project first.',
      );
    }
    final packageConfigContent = packageConfig.readAsStringSync();
    if (!_hasPackage(packageConfigContent, backend)) {
      final hint = _knownBackends.containsKey(backend)
          ? ' (the ${_knownBackends[backend]} backend)'
          : '';
      throw StateError(
        "Backend package '$backend'$hint is not in this project's package "
        'graph. Add it to dev_dependencies and run `dart pub get`.',
      );
    }

    final basaltDir = Directory(p.join(packageConfig.parent.path, 'basalt'));
    final entrypoint = File(p.join(basaltDir.path, 'entrypoint.dart'));
    final fingerprintFile = File(p.join(basaltDir.path, 'entrypoint.fingerprint'));
    final fingerprint = '$_formatVersion\n$backend\n$packageConfigContent';
    final stale = !entrypoint.existsSync() ||
        !fingerprintFile.existsSync() ||
        fingerprintFile.readAsStringSync() != fingerprint;
    if (stale) {
      basaltDir.createSync(recursive: true);
      entrypoint.writeAsStringSync(
        const EntrypointGenerator().generate(backendPackage: backend),
      );
      fingerprintFile.writeAsStringSync(fingerprint);
    }

    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', entrypoint.path, ...args],
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }

  /// Extracts the global `--config`/`-c` option so the bootstrapper reads the
  /// same file the CLI will (`--config path`, `--config=path`, `-c path`).
  String _configPath(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if ((arg == '--config' || arg == '-c') && i + 1 < args.length) {
        return args[i + 1];
      }
      if (arg.startsWith('--config=')) {
        return arg.substring('--config='.length);
      }
    }
    return 'basalt.yaml';
  }

  /// Walks up from [start] to the nearest `.dart_tool/package_config.json`.
  File? _findPackageConfig(Directory start) {
    var dir = start.absolute;
    while (true) {
      final candidate =
          File(p.join(dir.path, '.dart_tool', 'package_config.json'));
      if (candidate.existsSync()) return candidate;
      final parent = dir.parent;
      if (parent.path == dir.path) return null;
      dir = parent;
    }
  }

  /// Whether [packageConfigContent] lists a package named [package].
  bool _hasPackage(String packageConfigContent, String package) {
    final json = jsonDecode(packageConfigContent);
    if (json is! Map || json['packages'] is! List) return false;
    return (json['packages'] as List).any(
      (entry) => entry is Map && entry['name'] == package,
    );
  }
}
