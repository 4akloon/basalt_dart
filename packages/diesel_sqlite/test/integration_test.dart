import 'package:diesel/diesel.dart';
import 'package:diesel_sqlite/diesel_sqlite.dart';
import 'package:test/test.dart';

import 'test_schema.dart';

void main() {
  late SqliteConnection db;

  setUp(() async {
    db = SqliteConnection.memory();
    await db.executeSql('CREATE TABLE users ('
        'id INTEGER PRIMARY KEY, name TEXT NOT NULL, '
        'age INTEGER NOT NULL, active INTEGER NOT NULL)');
  });

  tearDown(() => db.close());

  Future<void> seed() async {
    await db.execute(insertInto(Users.table).value(Users.id.set(1)).value(Users.name.set('Bob')).value(Users.age.set(30)).value(Users.active.set(true)));
    await db.execute(insertInto(Users.table).value(Users.id.set(2)).value(Users.name.set('Alice')).value(Users.age.set(17)).value(Users.active.set(false)));
    await db.execute(insertInto(Users.table).value(Users.id.set(3)).value(Users.name.set('Carol')).value(Users.age.set(42)).value(Users.active.set(true)));
  }

  test('round-trip: insert then typed select', () async {
    await seed();
    final rows = await db.fetch(
      select2(Users.name, Users.age)
          .where(Users.age.ge(18))
          .orderBy(Users.age.desc()),
    );
    expect(rows, [('Carol', 42), ('Bob', 30)]);
    // Statically a (String, int) record:
    final (firstName, firstAge) = rows.first;
    expect(firstName, isA<String>());
    expect(firstAge, isA<int>());
  });

  test('bool and decoding round-trips', () async {
    await seed();
    final actives = await db.fetch(
      select1(Users.name).where(Users.active.eq(true)).orderBy(Users.name.asc()),
    );
    expect(actives, ['Bob', 'Carol']);
  });

  test('update returns affected rows and persists', () async {
    await seed();
    final n = await db.execute(update(Users.table).value(Users.age.set(31)).where(Users.name.eq('Bob')));
    expect(n, 1);
    expect(await db.fetch(select1(Users.age).where(Users.name.eq('Bob'))), [31]);
  });

  test('delete returns affected rows', () async {
    await seed();
    final n = await db.execute(deleteFrom(Users.table).where(Users.age.lt(18)));
    expect(n, 1);
    expect((await db.fetch(select1(Users.id))).length, 2);
  });

  test('transaction rolls back on error', () async {
    await seed();
    await expectLater(
      db.transaction((tx) async {
        await tx.execute(insertInto(Users.table).value(Users.id.set(99)).value(Users.name.set('Temp')).value(Users.age.set(1)).value(Users.active.set(false)));
        throw StateError('boom');
      }),
      throwsStateError,
    );
    // The insert must have been rolled back.
    expect(await db.fetch(select1(Users.id).where(Users.id.eq(99))), isEmpty);
  });

  test('nested transaction (savepoint) rolls back inner only', () async {
    await seed();
    await db.transaction((tx) async {
      await tx.execute(insertInto(Users.table).value(Users.id.set(10)).value(Users.name.set('Outer')).value(Users.age.set(50)).value(Users.active.set(true)));
      try {
        await tx.transaction((inner) async {
          await inner.execute(insertInto(Users.table).value(Users.id.set(11)).value(Users.name.set('Inner')).value(Users.age.set(60)).value(Users.active.set(true)));
          throw StateError('inner boom');
        });
      } on StateError {
        // swallow: outer continues
      }
    });
    expect(await db.fetch(select1(Users.name).where(Users.id.eq(10))), ['Outer']);
    expect(await db.fetch(select1(Users.id).where(Users.id.eq(11))), isEmpty);
  });
}
