// The core `basalt` package is a *pure* query builder: it turns a typed AST into
// `(String sql, List<Object?> params)` with no database driver involved. This
// example builds SELECT / INSERT / UPDATE / DELETE statements and serializes them
// with a tiny inline dialect. In a real app you'd depend on a backend package
// (e.g. `basalt_sqlite`) that ships a `Connection` + `SqlDialect` and runs them.
import 'package:basalt/basalt.dart';

/// A hand-written typed schema. The CLI's `generate-schema` emits a file like
/// this from a migrated database.
abstract final class Users {
  static const _t = 'users';
  static const id = PrimaryKey<int, Users>(_t, 'id', IntSqlType());
  static const name = ValueColumn<String, Users>(_t, 'name', StringSqlType());
  static const age = ValueColumn<int, Users>(_t, 'age', IntSqlType());
  static const table = TableRef<Users>(_t, [id, name, age]);
}

/// Minimal ANSI dialect: double-quoted identifiers and `?` placeholders. Real
/// backends implement this too — `basalt_sqlite` maps `bool`/`DateTime`, Postgres
/// uses `$N` placeholders — without the query builder changing.
final class AnsiDialect implements SqlDialect {
  const AnsiDialect();

  @override
  String quoteIdentifier(String name) => '"$name"';

  @override
  String placeholder(int index) => '?';

  @override
  Object? encodeParam(Object? value) => value;

  @override
  String? castType(SqlType<Object?> type) => null;
}

int _ignore(RowReader _) => 0;

void main() {
  final builder = QueryBuilder(const AnsiDialect());

  // SELECT — columns and predicates carry a phantom table type, so mixing tables
  // in one WHERE is a compile error, not a runtime surprise.
  final (selectSql, selectParams) = builder.buildSelect(
    from(Users.table)
        .select([Users.name, Users.age])
        .where(Users.age.ge(18))
        .orderBy(Users.age.desc())
        .map(_ignore),
  );
  print('SELECT: $selectSql');
  print('  params: $selectParams'); // [18]

  // INSERT — typed, column-scoped values.
  final (insertSql, insertParams) =
      QueryBuilder(const AnsiDialect()).buildWrite(
    insertInto(Users.table)
        .value(Users.id.set(1))
        .value(Users.name.set('Bob'))
        .value(Users.age.set(30)),
  );
  print('INSERT: $insertSql');
  print('  params: $insertParams'); // [1, Bob, 30]

  // UPDATE
  final (updateSql, updateParams) =
      QueryBuilder(const AnsiDialect()).buildWrite(
    update(Users.table).value(Users.age.set(31)).where(Users.name.eq('Bob')),
  );
  print('UPDATE: $updateSql');
  print('  params: $updateParams'); // [31, Bob]

  // DELETE
  final (deleteSql, deleteParams) =
      QueryBuilder(const AnsiDialect()).buildWrite(
    deleteFrom(Users.table).where(Users.age.lt(18)),
  );
  print('DELETE: $deleteSql');
  print('  params: $deleteParams'); // [18]
}
