part of 'table.dart';

/// Table descriptor: a table marker extends `TableRef<Self>` and exposes a
/// `static const table` singleton that its columns hold as their `owner`.
///
/// Cycle-safe by construction: the const constructor stores only [tableName],
/// while [columns] (the default projection for `from`/joins) is an overriding
/// *getter* the marker declares — getters are evaluated lazily at runtime, so
/// `table` and the column constants never form a const-initializer cycle.
///
/// ```dart
/// final class Users extends TableRef<Users> {
///   const Users._() : super('users');
///   static const table = Users._();
///   static const id = PrimaryKey<int, Users>(table, 'id', IntSqlType());
///   @override
///   List<TableColumn<Object?, Object?>> get columns => const [id];
/// }
/// ```
///
/// {@category schema}
abstract class TableRef<Tbl> implements QuerySource<Tbl> {
  const TableRef(this.tableName);
  @override
  final String tableName;

  @override
  String? get alias => null;

  @override
  TableColumn<T, Tbl> col<T>(TableColumn<T, Tbl> column) => column;

  /// Alias this table for a self-join — `Users.table.aliased('sender')`.
  TableAlias<Tbl> aliased(String alias) => TableAlias(alias, this);
}
