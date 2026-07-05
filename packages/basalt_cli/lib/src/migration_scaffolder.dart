import 'dart:io';

import 'package:path/path.dart' as p;

/// Scaffolds `<migrationsDir>/<version>_<name>/{up,down}.sql`, where `<version>`
/// is a basalt-compatible UTC timestamp (`%Y-%m-%d-%H%M%S`, e.g.
/// `2024-01-15-123456`) using basalt_dart's standard layout.
///
/// {@category migrations}
final class MigrationScaffolder {
  const MigrationScaffolder();

  /// Creates the migration directory and returns its path.
  String scaffold(String name, String migrationsDir) {
    final now = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final version = '${now.year}-${two(now.month)}-${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';

    final dir = Directory(p.join(migrationsDir, '${version}_$name'));
    dir.createSync(recursive: true);
    File(p.join(dir.path, 'up.sql'))
        .writeAsStringSync('-- Write the SQL to apply this migration here.\n');
    File(p.join(dir.path, 'down.sql'))
        .writeAsStringSync('-- Write the SQL to revert this migration here.\n');
    return dir.path;
  }
}
