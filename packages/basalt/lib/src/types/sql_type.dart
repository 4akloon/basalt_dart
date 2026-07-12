/// Mapping between a Dart type `T` and its on-the-wire SQL representation.
///
/// [SqlType] is a [Codec]: [Codec.encode] turns a Dart value into a
/// driver-ready parameter, [Codec.decode] turns a raw value returned by the
/// driver back into `T`. Built-in types live one-per-file under `sql_types/`
/// (e.g. [IntSqlType]) and are re-exported here; nullable variants wrap any
/// type in [NullableSqlType]. Their `const` constructors are what let columns
/// be `static const` and therefore usable inside annotations later. Custom
/// types are added the same way — by subclassing (see `doc/types.md`), not by
/// passing callbacks.
library;

import 'dart:convert';

export 'sql_types/blob_sql_type.dart';
export 'sql_types/boolean_sql_type.dart';
export 'sql_types/date_time_sql_type.dart';
export 'sql_types/double_sql_type.dart';
export 'sql_types/int_sql_type.dart';
export 'sql_types/nullable_sql_type.dart';
export 'sql_types/string_sql_type.dart';

/// {@category types}
abstract base class SqlType<T> extends Codec<T, Object?> {
  const SqlType();

  @override
  Object? encode(T input);

  @override
  T decode(Object? encoded);

  @override
  Converter<T, Object?> get encoder => _SqlTypeEncoder(this);

  @override
  Converter<Object?, T> get decoder => _SqlTypeDecoder(this);
}

final class _SqlTypeEncoder<T> extends Converter<T, Object?> {
  const _SqlTypeEncoder(this._type);
  final SqlType<T> _type;
  @override
  Object? convert(T input) => _type.encode(input);
}

final class _SqlTypeDecoder<T> extends Converter<Object?, T> {
  const _SqlTypeDecoder(this._type);
  final SqlType<T> _type;
  @override
  T convert(Object? input) => _type.decode(input);
}
