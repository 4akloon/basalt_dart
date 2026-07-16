import 'package:basalt/basalt.dart';
import 'package:basalt_postgres/basalt_postgres.dart';
import 'package:test/test.dart';

abstract final class Users {
  static const id = PrimaryKey<int, Users>('users', 'id', IntSqlType());
  static const name =
      ValueColumn<String, Users>('users', 'name', StringSqlType());
  static const age = ValueColumn<int, Users>('users', 'age', IntSqlType());
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
      insertInto(Users.table)
          .value(Users.id.set(1))
          .value(Users.name.set('Bob')),
    );
    expect(sql, r'INSERT INTO "users" ("id", "name") VALUES ($1, $2)');
    expect(params, [1, 'Bob']);
  });

  test('updateAll casts the first VALUES row only', () {
    final (sql, params) = QueryBuilder(const PostgresDialect()).buildWrite(
      updateAll(Users.table).keyedBy(Users.id).values([
        [Users.id.set(1), Users.name.set('A'), Users.age.set(10)],
        [Users.id.set(2), Users.name.set('B'), Users.age.set(20)],
      ]),
    );
    expect(
      sql,
      'WITH "__basalt_values"("id", "name", "age") '
      r'AS (VALUES (CAST($1 AS bigint), CAST($2 AS text), CAST($3 AS bigint)), '
      r'($4, $5, $6)) '
      'UPDATE "users" SET "name" = "__basalt_values"."name", '
      '"age" = "__basalt_values"."age" '
      'FROM "__basalt_values" '
      'WHERE "users"."id" = "__basalt_values"."id"',
    );
    expect(params, [1, 'A', 10, 2, 'B', 20]);
  });

  group('castType', () {
    const dialect = PostgresDialect();

    test('maps the core types to native Postgres names', () {
      expect(dialect.castType(const IntSqlType()), 'bigint');
      expect(dialect.castType(const StringSqlType()), 'text');
      expect(dialect.castType(const BooleanSqlType()), 'boolean');
      expect(dialect.castType(const DoubleSqlType()), 'double precision');
      expect(dialect.castType(const DateTimeSqlType()), 'timestamptz');
      expect(dialect.castType(const BlobSqlType()), 'bytea');
    });

    test('unwraps NullableSqlType to its inner codec', () {
      expect(
        dialect.castType(const NullableSqlType<int>(IntSqlType())),
        'bigint',
      );
      expect(
        dialect.castType(
          const NullableSqlType<Map<String, Object?>>(PostgresJsonbSqlType()),
        ),
        'jsonb',
      );
    });

    test('uses PostgresTypedSqlType for the native codecs', () {
      expect(dialect.castType(const PostgresJsonbSqlType()), 'jsonb');
      expect(dialect.castType(const PostgresUuidSqlType()), 'uuid');
      expect(dialect.castType(const PostgresNumericSqlType()), 'numeric');
      expect(dialect.castType(const PostgresArraySqlType<int>()), 'bigint[]');
      expect(dialect.castType(const PostgresArraySqlType<String>()), 'text[]');
      expect(
        dialect.castType(const PostgresArraySqlType<double>()),
        'double precision[]',
      );
      expect(
        dialect.castType(const PostgresArraySqlType<bool>()),
        'boolean[]',
      );
    });

    test('unknown types get no cast', () {
      expect(dialect.castType(const PostgresArraySqlType<DateTime>()), isNull);
      expect(dialect.castType(const _OpaqueSqlType()), isNull);
    });
  });
}

final class _OpaqueSqlType extends SqlType<String> {
  const _OpaqueSqlType();
  @override
  Object? encode(String input) => input;
  @override
  String decode(Object? encoded) => encoded as String;
}
