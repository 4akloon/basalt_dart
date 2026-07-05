# Schema

Tables are declared as `abstract final class`es with `static const` columns.
Using `const` means the very same `TableColumn` object is shared by the query
builder (`Users.age.gt(18)`) and by derive annotations (`@Column(Users.name)`),
since annotation arguments must be compile-time constants.

```dart
abstract final class Users extends TableRef<Users> {
  const Users._();

  static const id = PrimaryKey<int, Users>('id');
  static const name = ValueColumn<String, Users>('name');
  static const authorId = Ref<int, Users, Posts>('author_id');
}
```

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

- `TableRef` — the un-aliased source for a table (`from(Users)`).
- `TableAlias` — an aliased source, used when the same table appears twice in
  one query (self-joins).
- `Aggregate` / `RawSelection` / `ColumnValue` — supporting selectable/assignable
  types used by aggregation, raw SQL escape hatches, and INSERT/UPDATE values.
