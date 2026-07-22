import 'package:basalt/basalt.dart';

/// Shared hand-written schema for tests. Several tables so we can exercise
/// table-scoped type safety, foreign keys and joins.
final class Users extends TableRef<Users> {
  const Users._() : super('users');

  static const table = Users._();

  static const id = PrimaryKey<int, Users>(table, 'id', IntSqlType());
  static const name =
      ValueColumn<String, Users>(table, 'name', StringSqlType());
  static const age = ValueColumn<int, Users>(table, 'age', IntSqlType());
  static const active =
      ValueColumn<bool, Users>(table, 'active', BooleanSqlType());

  @override
  List<TableColumn<Object?, Object?>> get columns =>
      const [id, name, age, active];
}

final class Posts extends TableRef<Posts> {
  const Posts._() : super('posts');

  static const table = Posts._();

  static const id = PrimaryKey<int, Posts>(table, 'id', IntSqlType());
  static const authorId = Ref<int, Posts, Users>(
    table,
    'author_id',
    IntSqlType(),
    references: Users.id,
  );
  static const title =
      ValueColumn<String, Posts>(table, 'title', StringSqlType());
  static const views = ValueColumn<int, Posts>(table, 'views', IntSqlType());

  @override
  List<TableColumn<Object?, Object?>> get columns =>
      const [id, authorId, title, views];
}

final class Comments extends TableRef<Comments> {
  const Comments._() : super('comments');

  static const table = Comments._();

  static const id = PrimaryKey<int, Comments>(table, 'id', IntSqlType());
  static const postId = Ref<int, Comments, Posts>(
    table,
    'post_id',
    IntSqlType(),
    references: Posts.id,
  );
  static const body =
      ValueColumn<String, Comments>(table, 'body', StringSqlType());

  @override
  List<TableColumn<Object?, Object?>> get columns => const [id, postId, body];
}

/// Two foreign keys to the SAME table — needs aliased self-joins.
final class Messages extends TableRef<Messages> {
  const Messages._() : super('messages');

  static const table = Messages._();

  static const id = PrimaryKey<int, Messages>(table, 'id', IntSqlType());
  static const senderId = Ref<int, Messages, Users>(
    table,
    'sender_id',
    IntSqlType(),
    references: Users.id,
  );
  static const recipientId = Ref<int, Messages, Users>(
    table,
    'recipient_id',
    IntSqlType(),
    references: Users.id,
  );
  static const body =
      ValueColumn<String, Messages>(table, 'body', StringSqlType());

  @override
  List<TableColumn<Object?, Object?>> get columns =>
      const [id, senderId, recipientId, body];
}

/// Has a nullable column (`bio TEXT NULL`).
final class Profiles extends TableRef<Profiles> {
  const Profiles._() : super('profiles');

  static const table = Profiles._();

  static const id = PrimaryKey<int, Profiles>(table, 'id', IntSqlType());
  static const bio = ValueColumn<String?, Profiles>(
      table, 'bio', NullableSqlType(StringSqlType()));

  @override
  List<TableColumn<Object?, Object?>> get columns => const [id, bio];
}

// Data classes + reusable RowReader-based decoders — exactly what codegen would
// emit for `@Queryable(...)`. Decoders compose (a Comment can embed a Post that
// embeds a User) with no arity-specific machinery.
class User {
  const User(this.id, this.name, this.age, this.active);
  final int id;
  final String name;
  final int age;
  final bool active;
}

User readUser(RowReader r) => User(
      r.get(Users.id),
      r.get(Users.name),
      r.get(Users.age),
      r.get(Users.active),
    );
const userQueryable = RowMapper<User>(readUser);

class Post {
  // populated only when the query joins the author in
  const Post(this.id, this.authorId, this.title, this.views, {this.author});
  final int id;
  final int authorId;
  final String title;
  final int views;
  final User? author;
  Post withAuthor(User author) =>
      Post(id, authorId, title, views, author: author);
}

Post readPost(RowReader r) => Post(
      r.get(Posts.id),
      r.get(Posts.authorId),
      r.get(Posts.title),
      r.get(Posts.views),
    );
const postQueryable = RowMapper<Post>(readPost);

class Comment {
  // populated only when the query joins the post in
  const Comment(this.id, this.postId, this.body, {this.post});
  final int id;
  final int postId;
  final String body;
  final Post? post;
  Comment withPost(Post post) => Comment(id, postId, body, post: post);
}

Comment readComment(RowReader r) =>
    Comment(r.get(Comments.id), r.get(Comments.postId), r.get(Comments.body));
const commentQueryable = RowMapper<Comment>(readComment);
