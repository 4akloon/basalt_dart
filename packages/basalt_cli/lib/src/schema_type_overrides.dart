import 'package:basalt/basalt.dart';

/// One resolved column-type override for `generate-schema`: the exact Dart type
/// and `SqlType` constructor expression to emit, plus an optional import the
/// generated file needs for a custom symbol.
///
/// Both [dartType] and [sqlType] are written **verbatim**; in particular
/// [dartType] must equal the `SqlType`'s `T` — the generator cannot verify that
/// against the user's package.
///
/// {@category migrations}
final class TypeOverride {
  const TypeOverride({
    required this.dartType,
    required this.sqlType,
    this.import,
  });

  /// The Dart field type as written, e.g. `Map<String, Object?>`.
  final String dartType;

  /// The `SqlType` constructor expression as written, e.g. `JsonMapSqlType()`.
  final String sqlType;

  /// Import URI the generated schema needs for the override's symbols, or null
  /// when they are already exported by `package:basalt/basalt.dart`.
  final String? import;
}

/// Config-level column-type customization for `generate-schema`, parsed from the
/// optional `types:` block of `basalt.yaml`.
///
/// Overrides are resolved per column with the precedence **specific column >
/// native type > canonical type**, each falling back to the generator's
/// built-in mapping. Empty by default, so the block is fully optional.
///
/// {@category migrations}
final class SchemaTypeOverrides {
  const SchemaTypeOverrides({
    this.byColumn = const {},
    this.byColumnNullable = const {},
    this.byNative = const {},
    this.byNativeNullable = const {},
    this.byCanonical = const {},
    this.byCanonicalNullable = const {},
  });

  /// No overrides — every column uses the generator's built-in type mapping.
  const SchemaTypeOverrides.empty()
      : byColumn = const {},
        byColumnNullable = const {},
        byNative = const {},
        byNativeNullable = const {},
        byCanonical = const {},
        byCanonicalNullable = const {};

  /// Overrides keyed by `"table.column"`.
  final Map<String, TypeOverride> byColumn;

  /// Nullable-column variants of [byColumn].
  final Map<String, TypeOverride> byColumnNullable;

  /// Overrides keyed by normalized native type (see [normalizeNative]).
  final Map<String, TypeOverride> byNative;

  /// Nullable-column variants of [byNative].
  final Map<String, TypeOverride> byNativeNullable;

  /// Overrides keyed by canonical [ColumnType].
  final Map<ColumnType, TypeOverride> byCanonical;

  /// Nullable-column variants of [byCanonical].
  final Map<ColumnType, TypeOverride> byCanonicalNullable;

  /// Whether no overrides are configured.
  bool get isEmpty =>
      byColumn.isEmpty && byNative.isEmpty && byCanonical.isEmpty;

  /// The override for [column] of [table], or null to use the built-in mapping.
  ///
  /// Tries a specific-column match, then the column's native type (full match
  /// then base name), then its canonical type. For a nullable column the
  /// `*Nullable` variant wins over the base entry at each level.
  TypeOverride? resolve(String table, IntrospectedColumn column) {
    final nullable = column.isNullable;

    final columnKey = '$table.${column.name}';
    final byColumnMatch =
        (nullable ? byColumnNullable[columnKey] : null) ?? byColumn[columnKey];
    if (byColumnMatch != null) return byColumnMatch;

    if (column.rawType.isNotEmpty) {
      final normalized = normalizeNative(column.rawType);
      final base = _baseName(normalized);
      final byNativeMatch = (nullable ? byNativeNullable[normalized] : null) ??
          byNative[normalized] ??
          (nullable ? byNativeNullable[base] : null) ??
          byNative[base];
      if (byNativeMatch != null) return byNativeMatch;
    }

    return (nullable ? byCanonicalNullable[column.type] : null) ??
        byCanonical[column.type];
  }

  /// Normalizes a native type string for matching: trims, lowercases and
  /// collapses internal whitespace (so `timestamp  with time zone` matches
  /// `timestamp with time zone`).
  static String normalizeNative(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// The type name without any `(...)` size/precision suffix, so a `varchar`
  /// key matches a `varchar(255)` column.
  static String _baseName(String normalized) {
    final paren = normalized.indexOf('(');
    return paren == -1 ? normalized : normalized.substring(0, paren).trim();
  }

  /// Parses the `types:` node of `basalt.yaml` (a map, or null when absent).
  ///
  /// Throws [StateError] with a user-facing message on any malformed entry —
  /// the CLI surfaces it as `Error: <message>`.
  static SchemaTypeOverrides fromYaml(Object? node) {
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

    final (byColumn, byColumnNullable) =
        _stringSection(node['columns'], 'types.columns', (k) => k);
    final (byNative, byNativeNullable) =
        _stringSection(node['native'], 'types.native', normalizeNative);
    final (byCanonical, byCanonicalNullable) =
        _canonicalSection(node['canonical']);

    return SchemaTypeOverrides(
      byColumn: byColumn,
      byColumnNullable: byColumnNullable,
      byNative: byNative,
      byNativeNullable: byNativeNullable,
      byCanonical: byCanonical,
      byCanonicalNullable: byCanonicalNullable,
    );
  }

  static (Map<String, TypeOverride>, Map<String, TypeOverride>) _stringSection(
    Object? node,
    String ctx,
    String Function(String) keyOf,
  ) {
    final base = <String, TypeOverride>{};
    final nullable = <String, TypeOverride>{};
    if (node == null) return (base, nullable);
    if (node is! Map) {
      throw StateError('basalt.yaml: `$ctx` must be a mapping.');
    }
    for (final entry in node.entries) {
      final rawKey = entry.key.toString();
      final key = keyOf(rawKey);
      if (base.containsKey(key)) {
        throw StateError("basalt.yaml: `$ctx` has a duplicate key '$key'.");
      }
      final (baseOverride, nullableOverride) =
          _entry('$ctx.$rawKey', entry.value);
      base[key] = baseOverride;
      if (nullableOverride != null) nullable[key] = nullableOverride;
    }
    return (base, nullable);
  }

  static (Map<ColumnType, TypeOverride>, Map<ColumnType, TypeOverride>)
      _canonicalSection(Object? node) {
    final base = <ColumnType, TypeOverride>{};
    final nullable = <ColumnType, TypeOverride>{};
    if (node == null) return (base, nullable);
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
      final (baseOverride, nullableOverride) =
          _entry('types.canonical.$rawKey', entry.value);
      base[type] = baseOverride;
      if (nullableOverride != null) nullable[type] = nullableOverride;
    }
    return (base, nullable);
  }

  static (TypeOverride, TypeOverride?) _entry(String ctx, Object? node) {
    final base = _override(ctx, node);
    TypeOverride? nullable;
    if (node is Map && node['nullable'] != null) {
      nullable = _override('$ctx.nullable', node['nullable']);
    }
    return (base, nullable);
  }

  static TypeOverride _override(String ctx, Object? node) {
    if (node is! Map) {
      throw StateError(
        "basalt.yaml: `$ctx` must be a mapping with 'dart_type' and 'sql_type'.",
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
