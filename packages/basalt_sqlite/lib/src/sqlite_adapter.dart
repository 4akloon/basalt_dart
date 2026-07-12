import 'dart:async';
import 'dart:io';

import 'package:basalt/basalt.dart';
import 'package:basalt/tooling.dart';

import 'sqlite_connection.dart';

/// `BasaltAdapter` for the SQLite backend.
///
/// Supported `database:` options — exactly one key:
///
/// ```yaml
/// database:
///   path: app.db   # filesystem path, or `:memory:`
/// ```
///
/// The always-on [typeOverrides] preset restores fidelity lost to SQLite's
/// type affinity: columns declared `BOOLEAN`/`BOOL` or `DATETIME`/`TIMESTAMP`
/// introspect as plain `INTEGER`, but their declared type survives in
/// `rawType`, so `generate-schema` can emit `bool`/`DateTime` (portable core
/// types) instead of `int`.
///
/// {@category getting-started}
final class SqliteAdapter extends BasaltAdapter {
  const SqliteAdapter();

  @override
  String get name => 'sqlite';

  @override
  Future<Connection> open(Map<String, Object?> options) async =>
      SqliteConnection.open(_path(options));

  @override
  Future<void> reset(Map<String, Object?> options) async {
    final path = _path(options);
    if (path == ':memory:') return;
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  SchemaTypeOverrides get typeOverrides => const SchemaTypeOverrides(
        byNative: {
          'bool': _boolOverride,
          'boolean': _boolOverride,
          'datetime': _dateTimeOverride,
          'timestamp': _dateTimeOverride,
        },
      );

  static const _boolOverride =
      TypeOverride(dartType: 'bool', sqlType: 'BooleanSqlType()');
  static const _dateTimeOverride =
      TypeOverride(dartType: 'DateTime', sqlType: 'DateTimeSqlType()');

  /// Extracts and validates the `path` option.
  String _path(Map<String, Object?> options) {
    for (final key in options.keys) {
      if (key != 'path') {
        throw ArgumentError(
          "sqlite adapter: unknown database option '$key' (expected: path).",
        );
      }
    }
    final path = options['path'];
    if (path is! String || path.trim().isEmpty) {
      throw ArgumentError(
        "sqlite adapter: `database:` requires a non-empty 'path' "
        '(a filesystem path, or `:memory:`).',
      );
    }
    return path.trim();
  }
}
