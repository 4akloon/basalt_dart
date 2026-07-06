import '../sql_type.dart';

/// Stored as epoch milliseconds (sortable and timezone-free).
///
/// {@category types}
final class DateTimeSqlType extends SqlType<DateTime> {
  const DateTimeSqlType();

  @override
  String get sqlName => 'INTEGER';

  @override
  Object? encode(DateTime input) => input;

  @override
  DateTime decode(Object? encoded) => encoded is DateTime
      ? encoded
      : DateTime.fromMillisecondsSinceEpoch((encoded as num).toInt());
}
