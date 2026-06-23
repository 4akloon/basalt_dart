import 'dart:io';

import 'package:diesel/diesel.dart';
import 'package:path/path.dart' as p;

/// The migrations bookkeeping table (mirrors Diesel's `__diesel_schema_migrations`).
/// Defined with the query builder so the CLI dogfoods the ORM itself.
abstract final class _SchemaMigrations {
  static const _t = '__diesel_schema_migrations';
  static const version =
      ValueColumn<String, _SchemaMigrations>(_t, 'version', SqlType.text);
  static const runOn =
      ValueColumn<String, _SchemaMigrations>(_t, 'run_on', SqlType.text);
  static const table = TableRef<_SchemaMigrations>(_t, [version, runOn]);
}

/// One on-disk migration: `<dir>/<version>_<name>/{up,down}.sql`.
final class Migration {
  final String version;
  final String name;
  final File upFile;
  final File downFile;

  Migration(this.version, this.name, this.upFile, this.downFile);

  String get up => upFile.readAsStringSync();
  String? get down => downFile.existsSync() ? downFile.readAsStringSync() : null;
}

/// Snapshot of which migrations have run and which are pending.
typedef MigrationStatus = ({List<String> applied, List<Migration> pending});

/// Driver-agnostic migration engine: runs SQL files against any [Connection]
/// and tracks applied versions. The actual filesystem layout is discovered from
/// [migrationsDir].
final class MigrationRunner {
  final Connection connection;
  final String migrationsDir;

  MigrationRunner(this.connection, this.migrationsDir);

  Future<void> ensureTrackerTable() => connection.executeSql(
        'CREATE TABLE IF NOT EXISTS __diesel_schema_migrations '
        '(version TEXT NOT NULL PRIMARY KEY, run_on TEXT NOT NULL)',
      );

  /// Applied versions, ascending.
  Future<List<String>> appliedVersions() => connection.fetch(
        from(_SchemaMigrations.table)
            .orderBy(_SchemaMigrations.version.asc())
            .map((r) => r.get(_SchemaMigrations.version)),
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
      migrations.add(Migration(
        dirName.substring(0, sep),
        dirName.substring(sep + 1),
        upFile,
        File(p.join(entry.path, 'down.sql')),
      ));
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
        await tx.execute(insertInto(_SchemaMigrations.table)
            .value(_SchemaMigrations.version.set(migration.version))
            .value(_SchemaMigrations.runOn
                .set(DateTime.now().toUtc().toIso8601String())));
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
      await tx.execute(deleteFrom(_SchemaMigrations.table)
          .where(_SchemaMigrations.version.eq(version)));
    });
    return version;
  }
}

/// Scaffolds `<migrationsDir>/<timestamp>_<name>/{up,down}.sql` and returns the
/// created directory path.
String generateMigration(String name, String migrationsDir) {
  final now = DateTime.now().toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  final version =
      '${now.year}${two(now.month)}${two(now.day)}${two(now.hour)}${two(now.minute)}${two(now.second)}';

  final dir = Directory(p.join(migrationsDir, '${version}_$name'));
  dir.createSync(recursive: true);
  File(p.join(dir.path, 'up.sql'))
      .writeAsStringSync('-- Write the SQL to apply this migration here.\n');
  File(p.join(dir.path, 'down.sql'))
      .writeAsStringSync('-- Write the SQL to revert this migration here.\n');
  return dir.path;
}
