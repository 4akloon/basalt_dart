/// Mapping between a Dart type `T` and its on-the-wire SQL representation.
///
/// [encode] turns a Dart value into a driver-ready parameter; [decode] turns a
/// raw value returned by the driver back into `T`. Both are top-level function
/// tear-offs so the built-in [SqlType] instances can be `const` — which is what
/// lets columns be `static const` and therefore usable inside annotations later.
library;

class SqlType<T> {
  /// SQLite storage class / column type keyword (`INTEGER`, `TEXT`, ...).
  final String sqlName;
  final Object? Function(T value) encode;
  final T Function(Object? raw) decode;

  const SqlType(this.sqlName, this.encode, this.decode);

  static const SqlType<int> integer = SqlType('INTEGER', _encInt, _decInt);
  static const SqlType<String> text = SqlType('TEXT', _encString, _decString);
  static const SqlType<double> real = SqlType('REAL', _encDouble, _decDouble);
  static const SqlType<bool> boolean = SqlType('INTEGER', _encBool, _decBool);
  static const SqlType<List<int>> blob = SqlType('BLOB', _encBlob, _decBlob);

  /// Stored as epoch milliseconds (sortable and timezone-free).
  static const SqlType<DateTime> dateTime =
      SqlType('INTEGER', _encDateTime, _decDateTime);
}

Object? _encInt(int v) => v;
int _decInt(Object? r) => (r as num).toInt();

Object? _encString(String v) => v;
String _decString(Object? r) => r as String;

Object? _encDouble(double v) => v;
double _decDouble(Object? r) => (r as num).toDouble();

Object? _encBool(bool v) => v ? 1 : 0;
bool _decBool(Object? r) => (r as num) != 0;

Object? _encBlob(List<int> v) => v;
List<int> _decBlob(Object? r) => r as List<int>;

Object? _encDateTime(DateTime v) => v.millisecondsSinceEpoch;
DateTime _decDateTime(Object? r) =>
    DateTime.fromMillisecondsSinceEpoch((r as num).toInt());
