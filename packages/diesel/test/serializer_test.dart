import 'package:diesel/diesel.dart';
import 'package:test/test.dart';

import 'test_schema.dart';

/// Local dialect so the core package's serializer tests don't depend on any
/// backend: double-quoted identifiers and `?` placeholders (same as SQLite).
final class _TestDialect implements SqlDialect {
  const _TestDialect();

  @override
  String quoteIdentifier(String name) => '"$name"';

  @override
  String placeholder(int index) => '?';
}

CompiledQuery compileSelect(SelectStatement<dynamic, dynamic> s) =>
    QueryBuilder(const _TestDialect()).buildSelect(s);

CompiledQuery compileWrite(WriteStatement s) =>
    QueryBuilder(const _TestDialect()).buildWrite(s);

void main() {
  group('SELECT serialization', () {
    test('projection + where + order + limit', () {
      final (sql, params) = compileSelect(
        select2(Users.name, Users.age)
            .where(Users.age.ge(18))
            .orderBy(Users.age.desc())
            .limit(10),
      );
      expect(
        sql,
        'SELECT "users"."name", "users"."age" FROM "users" '
        'WHERE ("users"."age" >= ?) ORDER BY "users"."age" DESC LIMIT ?',
      );
      expect(params, [18, 10]);
    });

    test('combined predicates with and/or and operator sugar', () {
      final (sql, params) = compileSelect(
        select1(Users.id).where(Users.age.gt(21).and(Users.name.like('A%'))),
      );
      expect(
        sql,
        'SELECT "users"."id" FROM "users" '
        'WHERE (("users"."age" > ?) AND ("users"."name" LIKE ?))',
      );
      expect(params, [21, 'A%']);
    });

    test('IN, BETWEEN, IS NULL, bool encoding', () {
      final (sql, params) = compileSelect(
        select1(Users.id).where(Users.id
            .isIn([1, 2, 3])
            .and(Users.age.between(18, 65))
            .and(Users.active.eq(true))),
      );
      expect(
        sql,
        'SELECT "users"."id" FROM "users" WHERE '
        '(("users"."id" IN (?, ?, ?) AND "users"."age" BETWEEN ? AND ?) '
        'AND ("users"."active" = ?))',
      );
      expect(params, [1, 2, 3, 18, 65, 1]); // true -> 1
    });
  });

  group('write serialization', () {
    test('INSERT', () {
      final (sql, params) = compileWrite(
        insertInto(Users.table).value(Users.id.set(1)).value(Users.name.set('Bob')),
      );
      expect(sql, 'INSERT INTO "users" ("id", "name") VALUES (?, ?)');
      expect(params, [1, 'Bob']);
    });

    test('UPDATE with where', () {
      final (sql, params) = compileWrite(
        update(Users.table).value(Users.age.set(31)).where(Users.name.eq('Bob')),
      );
      expect(sql, 'UPDATE "users" SET "age" = ? WHERE ("users"."name" = ?)');
      expect(params, [31, 'Bob']);
    });

    test('DELETE with where', () {
      final (sql, params) =
          compileWrite(deleteFrom(Users.table).where(Users.age.lt(18)));
      expect(sql, 'DELETE FROM "users" WHERE ("users"."age" < ?)');
      expect(params, [18]);
    });
  });
}
