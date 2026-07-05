import 'dart:io';

import 'package:basalt/migration.dart';
import 'package:path/path.dart' as p;

/// Discovers migrations from a on-disk directory tree.
///
/// Layout: `<migrationsDir>/<version>_<name>/{up,down}.sql`.
///
/// {@category migrations}
final class DirectoryMigrationSource implements MigrationSource {
  DirectoryMigrationSource(this.migrationsDir);
  final String migrationsDir;

  @override
  Future<List<Migration>> discover() async {
    final dir = Directory(migrationsDir);
    if (!dir.existsSync()) return [];
    final migrations = <Migration>[];
    for (final entry in dir.listSync().whereType<Directory>()) {
      final dirName = p.basename(entry.path);
      final sep = dirName.indexOf('_');
      if (sep <= 0) continue;
      final upFile = File(p.join(entry.path, 'up.sql'));
      if (!upFile.existsSync()) continue;
      final downFile = File(p.join(entry.path, 'down.sql'));
      migrations.add(
        Migration(
          version: dirName.substring(0, sep),
          name: dirName.substring(sep + 1),
          up: upFile.readAsStringSync(),
          down: downFile.existsSync() ? downFile.readAsStringSync() : null,
        ),
      );
    }
    migrations.sort((a, b) => a.version.compareTo(b.version));
    return migrations;
  }
}
