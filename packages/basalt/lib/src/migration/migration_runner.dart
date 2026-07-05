import 'package:basalt/basalt.dart';

import 'migration_ddl.dart';
import 'migration_source.dart';
import 'migration_status.dart';
import 'schema_migrations_table.dart';

/// Driver-agnostic migration engine: runs SQL against any [Connection] and
/// tracks applied versions. Migration files are supplied by a [MigrationSource].
///
/// {@category migrations}
final class MigrationRunner {
  MigrationRunner(this.connection, this.source);
  final Connection connection;
  final MigrationSource source;

  Future<void> ensureTrackerTable() => connection.executeSql(
        createSchemaMigrationsTableSql(connection.dialect),
      );

  /// Applied versions, ascending.
  Future<List<String>> appliedVersions() => connection.fetch(
        from(SchemaMigrationsTable.table)
            .orderBy(SchemaMigrationsTable.version.asc())
            .map((r) => r.get(SchemaMigrationsTable.version)),
      );

  Future<MigrationStatus> status() async {
    await ensureTrackerTable();
    final applied = await appliedVersions();
    final appliedSet = applied.toSet();
    final pending = (await source.discover())
        .where((m) => !appliedSet.contains(m.version))
        .toList();
    return (applied: applied, pending: pending);
  }

  /// Applies every pending migration (each in a transaction) and returns the
  /// versions that ran.
  Future<List<String>> runPending() async {
    await ensureTrackerTable();
    final applied = (await appliedVersions()).toSet();
    final ran = <String>[];
    for (final migration in await source.discover()) {
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

  /// Reverts the most recently applied migration (runs its down SQL) and
  /// returns its version, or null if nothing was applied.
  Future<String?> revertLast() async {
    await ensureTrackerTable();
    final applied = await appliedVersions();
    if (applied.isEmpty) return null;
    final version = applied.last;

    String? down;
    for (final migration in await source.discover()) {
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
