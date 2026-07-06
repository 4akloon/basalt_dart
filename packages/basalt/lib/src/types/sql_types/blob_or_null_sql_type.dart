import '../sql_type.dart';

/// {@category types}
final class BlobOrNullSqlType extends SqlType<List<int>?> {
  const BlobOrNullSqlType();

  @override
  String get sqlName => 'BLOB';

  @override
  Object? encode(List<int>? input) => input;

  @override
  List<int>? decode(Object? encoded) => encoded as List<int>?;
}
