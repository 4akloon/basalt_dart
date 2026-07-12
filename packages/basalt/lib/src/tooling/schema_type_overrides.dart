import '../schema/introspection.dart';
import 'type_override.dart';

/// Column-type customization for `generate-schema`, from the `types:` block of
/// `basalt.yaml` (parsed by `SchemaTypeOverridesParser`) and/or a backend
/// adapter's presets.
///
/// Overrides are matched per column with the precedence **specific column >
/// native type > canonical type**, each falling back to the generator's
/// built-in mapping. Only the non-nullable form is registered; nullable columns
/// derive their variant automatically (see [TypeOverride.asNullable]). Combine
/// a user layer with an adapter preset via [overlay].
///
/// {@category tooling}
final class SchemaTypeOverrides {
  const SchemaTypeOverrides({
    this.byColumn = const {},
    this.byNative = const {},
    this.byCanonical = const {},
  });

  /// No overrides — every column uses the generator's built-in type mapping.
  const SchemaTypeOverrides.empty()
      : byColumn = const {},
        byNative = const {},
        byCanonical = const {};

  /// Overrides keyed by `"table.column"`.
  final Map<String, TypeOverride> byColumn;

  /// Overrides keyed by normalized native type (see [normalizeNativeType]).
  final Map<String, TypeOverride> byNative;

  /// Overrides keyed by canonical [ColumnType].
  final Map<ColumnType, TypeOverride> byCanonical;

  /// Whether no overrides are configured.
  bool get isEmpty =>
      byColumn.isEmpty && byNative.isEmpty && byCanonical.isEmpty;

  /// The override for [column] of [table], or null to use the built-in mapping.
  ///
  /// Tries a specific-column match, then the column's native type (full match
  /// then base name), then its canonical type. A nullable column gets the
  /// matched override's [TypeOverride.asNullable] variant.
  TypeOverride? resolve(String table, IntrospectedColumn column) {
    final match = _match(table, column);
    if (match == null) return null;
    return column.isNullable ? match.asNullable() : match;
  }

  TypeOverride? _match(String table, IntrospectedColumn column) {
    if (byColumn['$table.${column.name}'] case final override?) {
      return override;
    }
    if (column.rawType.isNotEmpty) {
      final normalized = normalizeNativeType(column.rawType);
      if (byNative[normalized] ?? byNative[_baseTypeName(normalized)]
          case final override?) {
        return override;
      }
    }
    return byCanonical[column.type];
  }

  /// Returns a copy where this set takes precedence over [base]: at each level,
  /// this map's entries win per key, and [base]'s remaining entries are kept.
  SchemaTypeOverrides overlay(SchemaTypeOverrides base) => SchemaTypeOverrides(
        byColumn: {...base.byColumn, ...byColumn},
        byNative: {...base.byNative, ...byNative},
        byCanonical: {...base.byCanonical, ...byCanonical},
      );
}

/// Normalizes a native type string for matching: trims, lowercases and
/// collapses internal whitespace (so `timestamp  with time zone` matches
/// `timestamp with time zone`).
///
/// {@category tooling}
String normalizeNativeType(String raw) =>
    raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// The type name without any `(...)` size/precision suffix, so a `varchar`
/// key matches a `varchar(255)` column.
String _baseTypeName(String normalized) {
  final paren = normalized.indexOf('(');
  return paren == -1 ? normalized : normalized.substring(0, paren).trim();
}
