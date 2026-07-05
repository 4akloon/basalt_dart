import 'package:basalt/basalt.dart';
import 'package:basalt_postgres/basalt_postgres.dart';
import 'package:test/test.dart';

abstract final class Users {
  static const id = PrimaryKey<int, Users>('users', 'id', SqlType.integer);
  static const name = ValueColumn<String, Users>('users', 'name', SqlType.text);
  static const age = ValueColumn<int, Users>('users', 'age', SqlType.integer);
  static const table = TableRef<Users>('users', [id, name, age]);
}

int _ignore(RowReader _) => 0;

void main() {
  test(r'SELECT uses numbered $N placeholders and quoted identifiers', () {
    final (sql, params) = QueryBuilder(const PostgresDialect()).buildSelect(
      from(Users.table)
          .select([Users.name])
          .where(Users.age.gt(18).and(Users.name.like('A%')))
          .map(_ignore),
    );
    expect(
      sql,
      'SELECT "users"."name" FROM "users" '
      r'WHERE (("users"."age" > $1) AND ("users"."name" LIKE $2))',
    );
    expect(params, [18, 'A%']);
  });

  test('INSERT numbers placeholders in order', () {
    final (sql, params) = QueryBuilder(const PostgresDialect()).buildWrite(
      insertInto(Users.table).value(Users.id.set(1)).value(Users.name.set('Bob')),
    );
    expect(sql, r'INSERT INTO "users" ("id", "name") VALUES ($1, $2)');
    expect(params, [1, 'Bob']);
  });
}
