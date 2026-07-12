import '../sql_type.dart';

/// Nullable variant of any [SqlType]: `null` passes through in both
/// directions, non-null values delegate to [inner].
///
/// Wraps once instead of hand-writing a `*OrNull` codec per type, so custom
/// types get their nullable form for free:
///
/// ```dart
/// static const deletedAt = ValueColumn<DateTime?, Users>(
///   Users.table, 'deleted_at', NullableSqlType(DateTimeSqlType()),
/// );
/// ```
///
/// The constructor is `const`, so wrapped types remain usable in
/// `static const` columns and annotation arguments.
///
/// In a column declaration `T` is inferred from the column's type. In a
/// context typed `SqlType<Object?>` inference degrades to
/// `NullableSqlType<Object>` — pass the argument explicitly there
/// (`NullableSqlType<int>(IntSqlType())`).
///
/// {@category types}
final class NullableSqlType<T extends Object> extends SqlType<T?> {
  const NullableSqlType(this.inner);

  /// The non-nullable codec handling non-null values.
  final SqlType<T> inner;

  @override
  Object? encode(T? input) => input == null ? null : inner.encode(input);

  @override
  T? decode(Object? encoded) => encoded == null ? null : inner.decode(encoded);
}
