import 'package:diesel_cli/diesel_cli.dart';
import 'package:diesel_sqlite/diesel_sqlite.dart';
import 'package:test/test.dart';

void main() {
  late SqliteConnection db;

  setUp(() async {
    db = SqliteConnection.memory();
    await db.executeSql('CREATE TABLE users ('
        'id INTEGER NOT NULL PRIMARY KEY, '
        'name TEXT NOT NULL, '
        'bio TEXT, ' // nullable
        'age INTEGER NOT NULL)');
    await db.executeSql('CREATE TABLE posts ('
        'id INTEGER NOT NULL PRIMARY KEY, '
        'author_id INTEGER NOT NULL REFERENCES users(id), '
        'title TEXT NOT NULL)');
  });

  tearDown(() => db.close());

  test('introspect reads tables, columns, nullability, pk and fks', () async {
    final tables = await db.introspect();
    expect(tables.map((t) => t.name), ['posts', 'users']); // sorted

    final users = tables.firstWhere((t) => t.name == 'users');
    final id = users.columns.firstWhere((c) => c.name == 'id');
    expect(id.isPrimaryKey, isTrue);
    expect(id.isNullable, isFalse);
    final bio = users.columns.firstWhere((c) => c.name == 'bio');
    expect(bio.isNullable, isTrue);

    final posts = tables.firstWhere((t) => t.name == 'posts');
    final authorId = posts.columns.firstWhere((c) => c.name == 'author_id');
    expect(authorId.foreignKey?.table, 'users');
    expect(authorId.foreignKey?.column, 'id');
  });

  test('generateSchema emits tables-only Dart (no data classes)', () async {
    final source = generateSchema(await db.introspect());

    expect(source, contains("import 'package:diesel/diesel.dart';"));
    expect(source, contains('abstract final class Users {'));
    expect(source,
        contains("static const id = PrimaryKey<int, Users>('users', 'id', SqlType.integer);"));
    expect(source,
        contains("static const bio = ValueColumn<String?, Users>('users', 'bio', SqlType.textOrNull);"));
    expect(source, contains('abstract final class Posts {'));
    expect(
      source,
      contains("static const authorId = Ref<int, Posts, Users>("
          "'posts', 'author_id', SqlType.integer, references: Users.id);"),
    );
    expect(source,
        contains("static const table = TableRef<Posts>('posts', [id, authorId, title]);"));

    // It must NOT generate data classes — only the schema.
    expect(source, isNot(contains('class User ')));
    expect(source, isNot(contains('RowReader')));
  });
}
