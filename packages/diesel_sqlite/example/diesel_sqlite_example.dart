import 'package:diesel/diesel.dart';
import 'package:diesel_sqlite/diesel_sqlite.dart';

/// Hand-written typed schema. In Stage 3 the CLI's `print-schema` generates a
/// file exactly like this from the migrated database.
abstract final class Users {
  static const _t = 'users';
  static const id = PrimaryKey<int, Users>(_t, 'id', SqlType.integer);
  static const name = ValueColumn<String, Users>(_t, 'name', SqlType.text);
  static const age = ValueColumn<int, Users>(_t, 'age', SqlType.integer);
  static const table = TableRef<Users>(_t);
}

Future<void> main() async {
  final db = SqliteConnection.memory();

  await db.executeSql(
    'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER NOT NULL)',
  );

  // INSERT — typed, column-scoped values, all inside one transaction.
  await db.transaction((tx) async {
    await tx.execute(insertInto(Users.table).value(Users.id.set(1)).value(Users.name.set('Bob')).value(Users.age.set(30)));
    await tx.execute(insertInto(Users.table).value(Users.id.set(2)).value(Users.name.set('Alice')).value(Users.age.set(17)));
    await tx.execute(insertInto(Users.table).value(Users.id.set(3)).value(Users.name.set('Carol')).value(Users.age.set(42)));
  });

  // SELECT — record-typed projection, type-safe WHERE/ORDER BY/LIMIT.
  final adults = await db.fetch(
    select2(Users.name, Users.age)
        .where(Users.age.ge(18))
        .orderBy(Users.age.desc())
        .limit(10),
  );
  print('Adults (name, age): $adults'); // [(Carol, 42), (Bob, 30)]
  for (final (name, age) in adults) {
    print('  $name is $age'); // statically (String, int)
  }

  // UPDATE
  final updated = await db.execute(update(Users.table).value(Users.age.set(31)).where(Users.name.eq('Bob')));
  print('Rows updated: $updated');

  // DELETE
  final deleted = await db.execute(deleteFrom(Users.table).where(Users.age.lt(18)));
  print('Rows deleted: $deleted');

  final names = await db.fetch(select1(Users.name).orderBy(Users.name.asc()));
  print('Remaining names: $names'); // [Bob, Carol]

  await db.close();
}
