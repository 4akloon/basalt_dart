import 'package:diesel/diesel.dart';

/// Shared hand-written schema for tests.
abstract final class Users {
  static const _t = 'users';
  static const id = PrimaryKey<int, Users>(_t, 'id', SqlType.integer);
  static const name = ValueColumn<String, Users>(_t, 'name', SqlType.text);
  static const age = ValueColumn<int, Users>(_t, 'age', SqlType.integer);
  static const active = ValueColumn<bool, Users>(_t, 'active', SqlType.boolean);
  static const table = TableRef<Users>(_t);
}

abstract final class Posts {
  static const _t = 'posts';
  static const id = PrimaryKey<int, Posts>(_t, 'id', SqlType.integer);
  static const authorId =
      Ref<int, Posts, Users>(_t, 'author_id', SqlType.integer, references: Users.id);
  static const title = ValueColumn<String, Posts>(_t, 'title', SqlType.text);
  static const views = ValueColumn<int, Posts>(_t, 'views', SqlType.integer);
  static const table = TableRef<Posts>(_t);
}
