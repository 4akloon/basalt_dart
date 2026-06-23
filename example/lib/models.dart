import 'package:diesel/diesel.dart';

import 'schema.dart';

/// Hand-written data classes + row readers for the generated [schema.dart].
///
/// `print-schema` generates only the schema (tables/columns); models live here.
/// Note: `active` is `int` because SQLite has no native boolean — the generated
/// `Users.active` is an INTEGER column (0/1).
class User {
  final int id;
  final String name;
  final int age;
  final int active;
  const User(this.id, this.name, this.age, this.active);

  @override
  String toString() => 'User(#$id $name, age $age)';
}

User readUser(RowReader r) =>
    User(r.get(Users.id), r.get(Users.name), r.get(Users.age), r.get(Users.active));

class Post {
  final int id;
  final String title;
  final int views;
  final User? author;
  const Post(this.id, this.title, this.views, {this.author});

  Post withAuthor(User author) => Post(id, title, views, author: author);

  @override
  String toString() => 'Post("$title", $views views, by ${author?.name})';
}

Post readPost(RowReader r) =>
    Post(r.get(Posts.id), r.get(Posts.title), r.get(Posts.views));
