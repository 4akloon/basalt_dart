import '../schema/introspection.dart';
import 'schema_type_overrides.dart';
import 'type_override.dart';

/// Parses the `types:` block of `basalt.yaml` into [SchemaTypeOverrides].
///
/// Kept apart from [SchemaTypeOverrides] so the resolution model stays small
/// and the (chunkier) parsing/validation lives on its own. Every malformed
/// entry throws [StateError] with a user-facing message the CLI surfaces as
/// `Error: <message>`.
///
/// {@category tooling}
final class SchemaTypeOverridesParser {
  const SchemaTypeOverridesParser();

  /// Parses the `types:` node (a map, or null when absent).
  SchemaTypeOverrides parse(Object? node) {
    if (node == null) return const SchemaTypeOverrides.empty();
    if (node is! Map) {
      throw StateError('basalt.yaml: `types:` must be a mapping.');
    }
    for (final key in node.keys) {
      if (key != 'columns' && key != 'native' && key != 'canonical') {
        throw StateError(
          "basalt.yaml: unknown key 'types.$key' "
          '(expected: columns, native, canonical).',
        );
      }
    }

    return SchemaTypeOverrides(
      byColumn: _stringSection(node['columns'], 'types.columns', (k) => k),
      byNative:
          _stringSection(node['native'], 'types.native', normalizeNativeType),
      byCanonical: _canonicalSection(node['canonical']),
    );
  }

  Map<String, TypeOverride> _stringSection(
    Object? node,
    String ctx,
    String Function(String) keyOf,
  ) {
    final result = <String, TypeOverride>{};
    if (node == null) return result;
    if (node is! Map) {
      throw StateError('basalt.yaml: `$ctx` must be a mapping.');
    }
    for (final entry in node.entries) {
      final rawKey = entry.key.toString();
      final key = keyOf(rawKey);
      if (result.containsKey(key)) {
        throw StateError("basalt.yaml: `$ctx` has a duplicate key '$key'.");
      }
      result[key] = _override('$ctx.$rawKey', entry.value);
    }
    return result;
  }

  Map<ColumnType, TypeOverride> _canonicalSection(Object? node) {
    final result = <ColumnType, TypeOverride>{};
    if (node == null) return result;
    if (node is! Map) {
      throw StateError('basalt.yaml: `types.canonical` must be a mapping.');
    }
    for (final entry in node.entries) {
      final rawKey = entry.key.toString();
      final type = ColumnType.values.firstWhere(
        (t) => t.name.toLowerCase() == rawKey.toLowerCase(),
        orElse: () => throw StateError(
          "basalt.yaml: types.canonical: unknown canonical type '$rawKey' "
          '(expected: ${ColumnType.values.map((t) => t.name).join(', ')}).',
        ),
      );
      result[type] = _override('types.canonical.$rawKey', entry.value);
    }
    return result;
  }

  TypeOverride _override(String ctx, Object? node) {
    if (node is! Map) {
      throw StateError(
        "basalt.yaml: `$ctx` must be a mapping with 'dart_type' and 'sql_type'.",
      );
    }
    if (node['nullable'] != null) {
      throw StateError(
        "basalt.yaml: `$ctx` no longer takes a 'nullable:' variant — register "
        'the non-nullable type only; nullable columns are wrapped in '
        'NullableSqlType automatically.',
      );
    }
    final dartType = node['dart_type'];
    final sqlType = node['sql_type'];
    if (dartType is! String || dartType.trim().isEmpty) {
      throw StateError("basalt.yaml: `$ctx` requires a non-empty 'dart_type'.");
    }
    if (sqlType is! String || sqlType.trim().isEmpty) {
      throw StateError("basalt.yaml: `$ctx` requires a non-empty 'sql_type'.");
    }
    final import = node['import'];
    if (import != null && import is! String) {
      throw StateError("basalt.yaml: `$ctx` 'import' must be a string.");
    }
    return TypeOverride(
      dartType: dartType.trim(),
      sqlType: sqlType.trim(),
      import: (import as String?)?.trim(),
    );
  }
}
