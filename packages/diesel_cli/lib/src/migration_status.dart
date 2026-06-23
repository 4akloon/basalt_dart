import 'migration.dart';

/// Snapshot of which migrations have run and which are pending.
typedef MigrationStatus = ({List<String> applied, List<Migration> pending});
