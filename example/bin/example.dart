import 'package:basalt/basalt.dart';
import 'package:basalt_example/models.dart';
import 'package:basalt_example/schema.dart';
import 'package:basalt_sqlite/basalt_sqlite.dart';

/// A tour of (almost) everything basalt_dart can do. Run AFTER applying the
/// migrations with the CLI:
///   dart run basalt_cli:basalt database reset
///   dart run bin/example.dart
Future<void> main() async {
  final db = SqliteConnection.open('example.db');

  await _seed(db);

  await _generatedQueries(db);
  await _singleTableQueries(db);
  await _manualJoins(db);
  await _writes(db);
  await _rawSql(db);

  await db.close();
}

/// INSERT + transactions (with a nested SAVEPOINT) + a clean re-seed so the
/// example is repeatable. Posts are deleted first because of the FK to users.
Future<void> _seed(Connection db) async {
  await db.execute(deleteFrom(Posts.table));
  await db.execute(deleteFrom(Users.table));

  await db.transaction((tx) async {
    // Carol is the top manager (no manager_id), Bob reports to Carol, Dave to Bob.
    // `toInsert()` comes from `@Insertable` — it sets every writable column.
    await tx.execute(const User(2, 'Carol', 42, 1).toInsert());
    await tx.execute(const User(1, 'Bob', 30, 1, managerId: 2).toInsert());

    // A nested transaction becomes a SAVEPOINT under the hood.
    await tx.transaction((inner) async {
      await inner
          .execute(const User(3, 'Dave', 25, 0, managerId: 1).toInsert());
    });

    for (final (id, author, title, views) in const [
      (1, 1, 'Hello', 150), // by Bob (mgr Carol)
      (2, 3, 'World', 90), // by Dave (mgr Bob)
      (3, 2, 'Untitled', 5), // by Carol (no manager)
    ]) {
      await tx.execute(
        insertInto(Posts.table)
            .value(Posts.id.set(id))
            .value(Posts.authorId.set(author))
            .value(Posts.title.set(title))
            .value(Posts.views.set(views)),
      );
    }
  });
}

/// The headline feature: self-mapping query getters emitted by `@Queryable` /
/// `@Relation`. No mapper is threaded through by hand — the getter owns the
/// joins, the aliases and the nested decoding, and stays chainable.
Future<void> _generatedQueries(Connection db) async {
  _header('Generated self-mapping join queries');

  // `postQuery` is `depth: 2`, so each Post carries its author AND the author's
  // manager (when present). Nullable FKs use LEFT JOIN, so Carol's "Untitled"
  // still appears — with `author.manager == null`.
  final posts = await db.fetch(postQuery.orderBy(Posts.views.desc()));
  print('Posts with author + author.manager (most viewed first):');
  for (final p in posts) {
    print('  $p');
  }

  // A self-referential relation: users joined to their own manager row. The
  // getter is still a `MappedQuery`, so we can keep refining it.
  // Combine predicates with `&`: chaining two `.where()` calls would replace the
  // first (each `where` sets THE clause), silently dropping `active = 1`.
  final managed = await db.fetch(
    userQuery
        .where(Users.active.eq(1) & Users.managerId.isNotNull())
        .orderBy(Users.name.asc()),
  );
  print('\nActive users that report to someone:');
  for (final u in managed) {
    print('  $u');
  }
}

/// Single-table, strongly-typed `WHERE` building: every comparison/combinator,
/// plus `limit`/`offset`, reusing the generated `userMapper`.
Future<void> _singleTableQueries(Connection db) async {
  _header('Single-table queries & the predicate DSL');

  // and / or, plus operator sugar (`>` and `&`).
  final seniorActive = await db.fetch(
    from(Users.table)
        .where((Users.age > 28) & Users.active.eq(1))
        .orderBy(Users.age.desc())
        .map(userMapper.read),
  );
  print('Active users older than 28: '
      '${seniorActive.map((u) => u.name).toList()}');

  // isIn, between, like, ne — and limit/offset for paging.
  final byName = await db.fetch(
    from(Users.table)
        .where(Users.name.like('%a%').and(Users.id.isIn([1, 2, 3])))
        .map(userMapper.read),
  );
  print('Users whose name contains "a": '
      '${byName.map((u) => u.name).toList()}');

  final midAge = await db.fetch(
    from(Users.table)
        .where(Users.age.between(26, 45))
        .orderBy(Users.age.asc())
        .limit(2)
        .offset(0)
        .map(userMapper.read),
  );
  print('Two youngest aged 26..45: ${midAge.map((u) => u.name).toList()}');

  // isNull / isNotNull against the nullable self-FK.
  final topManagers = await db.fetch(
    from(Users.table).where(Users.managerId.isNull()).map(userMapper.read),
  );
  print('Top managers (no manager_id): '
      '${topManagers.map((u) => u.name).toList()}');
}

/// Hand-written joins when you want full control: `innerJoin`/`leftJoin`,
/// FK-based (`onFk:`) and explicit (`on:`) conditions, projection narrowing
/// with `select`, and composing the generated readers inside a manual `map`.
Future<void> _manualJoins(Connection db) async {
  _header('Manual joins & projection control');

  // leftJoin keeps every post even if the author row were missing; we compose
  // the generated postMapper + userMapper by hand on the same RowReader.
  final joined = await db.fetch(
    from(Posts.table)
        .leftJoin(Users.table, onFk: Posts.authorId)
        .orderBy(Posts.id.asc())
        .map(
          (r) => '${postMapper.read(r).title} <- ${userMapper.read(r).name}',
        ),
  );
  print('Every post with its author (leftJoin): $joined');

  // Narrow the projection with `select`, and read raw column values directly.
  final titles = await db.fetch(
    from(Posts.table)
        .select([Posts.title, Posts.views])
        .where(Posts.views.ge(90))
        .orderBy(Posts.views.desc())
        .map((r) => '${r.get(Posts.title)} (${r.get(Posts.views)})'),
  );
  print('Popular post titles (>=90 views): $titles');

  // A self-join expressed by hand with an explicit `on:` and table aliases —
  // exactly what the codegen automates for `@Relation`.
  final mgr = Users.table.aliased('mgr');
  final pairs = await db.fetch(
    from(Users.table)
        .innerJoin(mgr, on: Users.managerId.eqColumn(mgr.col(Users.id)))
        .map((r) => '${r.get(Users.name)} -> ${r.get(mgr.col(Users.name))}'),
  );
  print('Reporting lines (name -> manager): $pairs');
}

/// UPDATE / DELETE with typed `WHERE`, returning affected-row counts.
Future<void> _writes(Connection db) async {
  _header('Writes (UPDATE / DELETE)');

  // `toUpdate()` comes from `@AsChangeset` — it builds the SET clause from every
  // writable column; we add the WHERE. `findUser` (generated bare find-by-PK)
  // fetches Dave, then we re-activate him by persisting his row.
  final dave = await findUser(3).first(db);
  final activated = await db.execute(
    User(dave.id, dave.name, dave.age, 1, managerId: dave.managerId)
        .toUpdate()
        .where(Users.id.eq(dave.id)),
  );
  print('Reactivated $activated user(s).');

  final deleted = await db.execute(
    deleteFrom(Posts.table).where(Posts.views.lt(10)),
  );
  print('Deleted $deleted low-traffic post(s).');

  final remaining =
      await db.fetch(from(Posts.table).map((r) => r.get(Posts.title)));
  print('Remaining posts: $remaining');
}

/// Escape hatches for raw SQL when the builder is not enough.
Future<void> _rawSql(Connection db) async {
  _header('Raw SQL escape hatches');

  final rows = await db.queryRaw(
    'SELECT COUNT(*) AS n, AVG(age) AS avg_age FROM users WHERE active = ?',
    [1],
  );
  final row = rows.single;
  print('Active users: ${row['n']}, average age: ${row['avg_age']}');

  await db.executeSql('UPDATE users SET age = age + 1 WHERE id = ?', [1]);
  final bob = await db
      .fetch(from(Users.table).where(Users.id.eq(1)).map(userMapper.read));
  print('After raw birthday bump: ${bob.single}');
}

void _header(String title) => print('\n=== $title ===');
