import 'package:diesel/diesel.dart';

/// Shared hand-written schema for tests. Several tables so we can exercise
/// table-scoped type safety, foreign keys and joins.
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

/// Intentionally unrelated table — used to prove the runtime FROM/JOIN scope
/// check rejects columns from tables that aren't part of the query.
abstract final class Comments {
  static const _t = 'comments';
  static const id = PrimaryKey<int, Comments>(_t, 'id', SqlType.integer);
  static const table = TableRef<Comments>(_t);
}
