import 'package:diesel/diesel.dart';

/// Shared hand-written schema for tests. Two tables so we can exercise (and
/// document) table-scoped type safety.
abstract final class Users {
  static const _t = 'users';
  static const id = Column<int, Users>(_t, 'id', SqlType.integer);
  static const name = Column<String, Users>(_t, 'name', SqlType.text);
  static const age = Column<int, Users>(_t, 'age', SqlType.integer);
  static const active = Column<bool, Users>(_t, 'active', SqlType.boolean);
  static const table = TableRef<Users>(_t, [id, name, age, active]);
}

abstract final class Posts {
  static const _t = 'posts';
  static const id = Column<int, Posts>(_t, 'id', SqlType.integer);
  static const title = Column<String, Posts>(_t, 'title', SqlType.text);
  static const table = TableRef<Posts>(_t, [id, title]);
}
