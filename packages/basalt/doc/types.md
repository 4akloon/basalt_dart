# Types

`SqlType<T>` is a [`Codec<T, Object?>`](https://api.dart.dev/dart-convert/Codec-class.html)
defining how a Dart value is encoded into a driver parameter and decoded back.
Each built-in type is its own class with a `const` constructor (which is what
lets columns be `static const` and usable in annotations).

## Built-in types

| `SqlType` | Dart `T` | Notes |
|---|---|---|
| `IntSqlType` | `int` | |
| `StringSqlType` | `String` | |
| `DoubleSqlType` | `double` | |
| `BooleanSqlType` | `bool` | On SQLite `true`→`1`, `false`→`0`; any non-zero decodes to `true`. |
| `BlobSqlType` | `List<int>` | |
| `DateTimeSqlType` | `DateTime` | On SQLite stored as epoch milliseconds (sortable, timezone-free). |

How a value is stored (column type, driver representation) is the backend's
business — see each backend package's type-mapping guide.

## Cross-backend values

Encoders produce a **canonical** Dart value (`bool` stays `bool`, `DateTime`
stays `DateTime`); each backend's `SqlDialect.encodeParam` adapts it to the
driver form — SQLite maps `bool`→`int` and `DateTime`→epoch-ms, while Postgres
binds them natively. Decoders are lenient (accept either representation). The
same schema and query DSL run unchanged on SQLite and Postgres.

## Nullable variants

For columns that allow `NULL`, wrap any type in `NullableSqlType` — the column
type becomes `T?`:

```dart
static const deletedAt = ValueColumn<DateTime?, Users>(
  Users.table, 'deleted_at', NullableSqlType(DateTimeSqlType()),
);
```

The wrapper passes `null` through in both directions and delegates non-null
values to the inner codec, so custom types get their nullable form for free —
no hand-written `*OrNull` duplicate. The **non-null** decoders intentionally
throw on `NULL`, which surfaces an unexpected `NULL` in a column you declared
non-nullable.

For null **predicates**, use `col.isNull()` / `col.isNotNull()` (an `eq(null)`
would emit `= NULL`, which is never true in SQL).

## Custom type codecs

`SqlType<T>` **is** the codec extension point — subclass it and implement
`encode` and `decode`. Keep the constructor `const` so it works in
`static const` columns. For example, an enum stored by name:

```dart
enum Role { admin, user, guest }

final class RoleSqlType extends SqlType<Role> {
  const RoleSqlType();

  @override
  Object? encode(Role input) => input.name;

  @override
  Role decode(Object? encoded) => Role.values.byName(encoded as String);
}

// in the schema:
static const role = ValueColumn<Role, Accounts>('accounts', 'role', RoleSqlType());
```

The custom type flows through reads (`r.get(Accounts.role)` → `Role`), writes
(`Accounts.role.set(Role.admin)`), and predicates (`Accounts.role.eq(Role.admin)`).
`generate-schema` emits built-in types by default; to have it emit a custom
`SqlType` instead of hand-editing the generated schema, configure a `types:`
override in `basalt.yaml` (see the `basalt_cli` guide).
