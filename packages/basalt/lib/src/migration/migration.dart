/// One migration: `<version>_<name>` with resolved `up` / optional `down` SQL.
///
/// {@category migrations}
final class Migration {
  const Migration({
    required this.version,
    required this.name,
    required this.up,
    this.down,
  });

  /// Ordering key — the directory-name prefix before the first `_`.
  final String version;

  /// Human-readable suffix after the first `_`.
  final String name;

  /// SQL applied by [MigrationRunner.runPending].
  final String up;

  /// SQL applied by [MigrationRunner.revertLast], or null when absent.
  final String? down;
}
