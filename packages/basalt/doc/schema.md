# Schema

A table is a `final class` extending `TableRef<Self>`, with a private const
constructor and a `static const table` singleton. Columns are `static const`
objects holding a typed reference to that singleton — using `const` means the
very same `TableColumn` object is shared by the query builder
(`Users.age.gt(18)`) and by derive annotations (`@Column(Users.name)`), since
annotation arguments must be compile-time constants.

```dart
final class Users extends TableRef<Users> {
  const Users._() : super('users');

  static const table = Users._();

  static const id = PrimaryKey<int, Users>(table, 'id', IntSqlType());
  static const name = ValueColumn<String, Users>(table, 'name', StringSqlType());
  static const managerId = Ref<int?, Users, Users>(
      table, 'manager_id', NullableSqlType(IntSqlType()),
      references: Users.id);

  @override
  List<TableColumn<Object?, Object?>> get columns => const [id, name, managerId];
}
```

The shared type parameter ties each column to its own table: passing
`Customers.table` to a `TableColumn<T, Users>` is a compile error.

## Why `columns` is a getter

`table` and the columns reference each other — `id` holds `table`, and the
default projection lists `id`. As two `const` fields that would be a
const-initializer cycle, which Dart rejects. Overriding `columns` as a *getter*
breaks the cycle: getters are evaluated lazily at runtime, so `table`'s
initializer depends on nothing and every column constant only depends on
`table`. Foreign keys stay cycle-free the same way — a `Ref` points at the
target's `PrimaryKey` constant, whose `table` singleton lists its columns only
through the getter.

## The column hierarchy

`TableColumn` is `sealed`: every column is exactly one of

- `ValueColumn` — a plain column,
- `PrimaryKey` — the table's primary key,
- `Ref` — a foreign key, carrying its target table as a type parameter.

Being sealed lets the join API and codegen pattern-match on the column kind
(e.g. to auto-derive FK-aware joins) and keeps the switch exhaustive as new
column kinds are added.

Every `TableColumn` is also a `Selection`, so it can be read straight out of a
row — see `RowReader` in **Query Builder**.

## Table markers and sources

- `TableRef` — the un-aliased source for a table (`from(Users.table)`).
- `TableAlias` — an aliased source, used when the same table appears twice in
  one query (self-joins).
- `Aggregate` / `RawSelection` / `ColumnValue` — supporting selectable/assignable
  types used by aggregation, raw SQL escape hatches, and INSERT/UPDATE values.
