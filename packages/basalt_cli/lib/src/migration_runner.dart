import 'dart:io';

import 'package:basalt/basalt.dart';
import 'package:path/path.dart' as p;

import 'migration.dart';
import 'migration_status.dart';
import 'schema_migrations_table.dart';

/// Driver-agnostic migration engine: runs SQL files against any [Connection]
/// and tracks applied versions. The actual filesystem layout is discovered from
/// [migrationsDir].
///
/// {@category migrations}
final class MigrationRunner {
  MigrationRunner(this.connection, this.migrationsDir);
  final Connection connection;
  final String migrationsDir;

  Future<void> ensureTrackerTable() => connection.executeSql(
        'CREATE TABLE IF NOT EXISTS __basalt_schema_migrations '
        '(version VARCHAR(50) PRIMARY KEY NOT NULL, '
        'run_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)',
      );

  /// Applied versions, ascending.
  Future<List<String>> appliedVersions() => connection.fetch(
        from(SchemaMigrationsTable.table)
            .orderBy(SchemaMigrationsTable.version.asc())
            .map((r) => r.get(SchemaMigrationsTable.version)),
      );

  /// Migrations found on disk, ascending by version.
  List<Migration> discover() {
    final dir = Directory(migrationsDir);
    if (!dir.existsSync()) return [];
    final migrations = <Migration>[];
    for (final entry in dir.listSync().whereType<Directory>()) {
      final dirName = p.basename(entry.path);
      final sep = dirName.indexOf('_');
      if (sep <= 0) continue;
      final upFile = File(p.join(entry.path, 'up.sql'));
      if (!upFile.existsSync()) continue;
      migrations.add(
        Migration(
          dirName.substring(0, sep),
          dirName.substring(sep + 1),
          upFile,
          File(p.join(entry.path, 'down.sql')),
        ),
      );
    }
    migrations.sort((a, b) => a.version.compareTo(b.version));
    return migrations;
  }

  Future<MigrationStatus> status() async {
    await ensureTrackerTable();
    final applied = await appliedVersions();
    final appliedSet = applied.toSet();
    final pending =
        discover().where((m) => !appliedSet.contains(m.version)).toList();
    return (applied: applied, pending: pending);
  }

  /// Applies every pending migration (each in a transaction) and returns the
  /// versions that ran.
  Future<List<String>> runPending() async {
    await ensureTrackerTable();
    final applied = (await appliedVersions()).toSet();
    final ran = <String>[];
    for (final migration in discover()) {
      if (applied.contains(migration.version)) continue;
      await connection.transaction((tx) async {
        await tx.executeSql(migration.up);
        await tx.execute(
          insertInto(SchemaMigrationsTable.table)
              .value(SchemaMigrationsTable.version.set(migration.version))
              .value(SchemaMigrationsTable.runOn.set(_runOn())),
        );
      });
      ran.add(migration.version);
    }
    return ran;
  }

  /// Reverts the most recently applied migration (runs its down.sql) and
  /// returns its version, or null if nothing was applied.
  Future<String?> revertLast() async {
    await ensureTrackerTable();
    final applied = await appliedVersions();
    if (applied.isEmpty) return null;
    final version = applied.last;

    String? down;
    for (final migration in discover()) {
      if (migration.version == version) {
        down = migration.down;
        break;
      }
    }

    await connection.transaction((tx) async {
      if (down case final sql? when sql.trim().isNotEmpty) {
        await tx.executeSql(sql);
      }
      await tx.execute(
        deleteFrom(SchemaMigrationsTable.table)
            .where(SchemaMigrationsTable.version.eq(version)),
      );
    });
    return version;
  }

  /// `run_on` value in the same shape as basalt / SQLite `CURRENT_TIMESTAMP`
  /// (UTC `YYYY-MM-DD HH:MM:SS`), so the tracker table is interchangeable.
  static String _runOn() {
    final t = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
