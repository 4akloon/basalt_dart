/// One resolved column-type override for `generate-schema`: the exact Dart type
/// and `SqlType` constructor expression to emit, plus an optional import the
/// generated file needs for a custom symbol.
///
/// Register the **non-nullable** form; a nullable column derives its variant
/// automatically via [asNullable] (wrapping the codec in `NullableSqlType`), so
/// there is no separate nullable registration.
///
/// Both [dartType] and [sqlType] are written **verbatim**; in particular
/// [dartType] must equal the `SqlType`'s `T` — the generator cannot verify that
/// against the user's package.
///
/// {@category tooling}
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

  /// The nullable variant of this override: the Dart type gains `?` and the
  /// codec is wrapped in `NullableSqlType`. The [import] is unchanged
  /// (`NullableSqlType` comes from `package:basalt/basalt.dart`).
  TypeOverride asNullable() => TypeOverride(
        dartType: '$dartType?',
        sqlType: 'NullableSqlType($sqlType)',
        import: import,
      );
}
