import '../sql_type.dart';

/// {@category types}
final class BlobSqlType extends SqlType<List<int>> {
  const BlobSqlType();

  @override
  String get sqlName => 'BLOB';

  @override
  Object? encode(List<int> input) => input;

  @override
  List<int> decode(Object? encoded) => encoded as List<int>;
}
