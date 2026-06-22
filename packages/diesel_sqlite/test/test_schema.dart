import 'package:diesel/diesel.dart';

/// Shared hand-written schema for tests.
abstract final class Users {
  static const _t = 'users';
  static const id = Column<int, Users>(_t, 'id', SqlType.integer);
  static const name = Column<String, Users>(_t, 'name', SqlType.text);
  static const age = Column<int, Users>(_t, 'age', SqlType.integer);
  static const active = Column<bool, Users>(_t, 'active', SqlType.boolean);
  static const table = TableRef<Users>(_t, [id, name, age, active]);
}
