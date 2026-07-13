// `PostgresDialect` serializes the same typed AST as every other backend, using
// numbered `$N` placeholders and quoted identifiers. This example needs no server
// — it shows the pure `(sql, params)` output. To run against a real database use
// `PostgresConnection.open(...)`, which implements the same `Connection` interface
// (transactions, savepoints, introspection) as the SQLite backend.
import 'package:basalt/basalt.dart';
import 'package:basalt_postgres/basalt_postgres.dart';

abstract final class Users {
  static const _t = 'users';
  static const id = PrimaryKey<int, Users>(_t, 'id', IntSqlType());
  static const name = ValueColumn<String, Users>(_t, 'name', StringSqlType());
  static const age = ValueColumn<int, Users>(_t, 'age', IntSqlType());
  static const table = TableRef<Users>(_t, [id, name, age]);
}

int _ignore(RowReader _) => 0;

void main() {
  final (selectSql, selectParams) =
      QueryBuilder(const PostgresDialect()).buildSelect(
    from(Users.table)
        .select([Users.name])
        .where(Users.age.gt(18).and(Users.name.like('A%')))
        .map(_ignore),
  );
  print(
      'SELECT: $selectSql'); // ... WHERE (("users"."age" > $1) AND ("users"."name" LIKE $2))
  print('  params: $selectParams'); // [18, A%]

  final (insertSql, insertParams) =
      QueryBuilder(const PostgresDialect()).buildWrite(
    insertInto(Users.table).value(Users.id.set(1)).value(Users.name.set('Bob')),
  );
  print(
      'INSERT: $insertSql'); // INSERT INTO "users" ("id", "name") VALUES ($1, $2)
  print('  params: $insertParams'); // [1, Bob]
}
