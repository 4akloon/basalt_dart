import 'package:basalt/basalt.dart';
import 'package:test/test.dart';

// Const-constructibility in a `static const` column — the compile-time
// guarantee that makes the wrapper usable in schemas and annotations.
abstract final class Users {
  static const nickname = ValueColumn<String?, Users>(
    'users',
    'nickname',
    NullableSqlType(StringSqlType()),
  );
}

void main() {
  group('NullableSqlType', () {
    test('null passes through in both directions', () {
      const type = NullableSqlType(IntSqlType());
      expect(type.encode(null), isNull);
      expect(type.decode(null), isNull);
    });

    test('non-null values delegate to the inner codec', () {
      const int_ = NullableSqlType(IntSqlType());
      expect(int_.encode(7), 7);
      expect(int_.decode(7), 7);

      const bool_ = NullableSqlType(BooleanSqlType());
      expect(bool_.decode(1), isTrue);
      expect(bool_.decode(false), isFalse);

      const dateTime = NullableSqlType(DateTimeSqlType());
      final moment = DateTime.fromMillisecondsSinceEpoch(1234);
      expect(dateTime.encode(moment), moment);
      expect(dateTime.decode(1234), moment);

      const double_ = NullableSqlType(DoubleSqlType());
      expect(double_.decode(1), 1.0);

      const string = NullableSqlType(StringSqlType());
      expect(string.decode('hi'), 'hi');

      const blob = NullableSqlType(BlobSqlType());
      expect(blob.decode([1, 2]), [1, 2]);
    });

    test('works as a static const column type', () {
      expect(Users.nickname.type.decode(null), isNull);
      expect(Users.nickname.type.decode('kim'), 'kim');
    });
  });
}
