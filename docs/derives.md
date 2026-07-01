# Derives (codegen)

`diesel_codegen` is a `build_runner`/`source_gen` generator that derives row mappers and write statements for
your data classes from five annotations (all in `package:diesel`). It is the Dart analog of diesel-rs's
`#[derive(...)]` macros.

## Setup

```yaml
dev_dependencies:
  diesel_codegen:
  build_runner: ^2.4.0
```

Add a `part` directive and run the builder:

```dart
import 'package:diesel/diesel.dart';
import 'schema.dart';

part 'user.g.dart';
```

```sh
dart run build_runner build
```

A class may carry several annotations; each generator contributes its own (non-overlapping) code to the one
`<file>.g.dart`.

## Annotations

| Annotation | Level | Generates |
|---|---|---|
| `@Queryable(table)` | class | `$XFromRow` reader, `const xMapper = RowMapper<X>(…)`, an `xQuery` getter (a join query when the class has `@Relation`s, otherwise a select-narrowing subset query), and a bare `findX(pk)` when the class maps a `PrimaryKey` |
| `@Insertable(table)` | class | `extension XInsert { InsertStatement<T> toInsert() }` |
| `@AsChangeset(table)` | class | `extension XChangeset { UpdateStatement<T> toUpdate() }` (SET only) |
| `@Column(col, {readOnly, writeOnly})` | field | column mapping + read/write direction |
| `@Relation(fk, {depth})` | field | a joined, nested related object (read-side) |

The class annotations are **independent**: a write-only DTO can be `@Insertable` alone.

## Field mapping

Each unnamed-constructor parameter maps to a column. By default the field name selects the column by matching
the schema's camelCase accessor (`managerId` → `Users.managerId`). Override or tune it with `@Column`:

```dart
@Column(Users.name) final String displayName;          // rename: field ≠ column
@Column(Users.id, readOnly: true) final int id;        // read on SELECT, skip INSERT/UPDATE
@Column(Users.token, writeOnly: true) final String? token;  // write, but skip the row reader
```

- **`readOnly`** — present in the `@Queryable` reader, excluded from `toInsert()` and `toUpdate()`'s SET
  (autoincrement PKs, server defaults).
- **`writeOnly`** — excluded from the row reader (the parameter must then be optional so its default is used),
  included in writes.
- Setting **both** is a generation error — a field that is neither read nor written isn't a column; use a
  getter for computed values. (There is no `@ignore`; make computed values getters, not constructor params.)

## `@Queryable` output

```dart
@Queryable(Users.table)
class User {
  final int id; final String name; final int age; final int active;
  const User(this.id, this.name, this.age, this.active);
}
```

generates a reusable mapper:

```dart
final users = await db.fetch(from(Users.table).map(userMapper.read));
// or: .mapWith(userMapper)
```

The generated `$XFromRow` reader is alias-parameterized and **composable** — it can be called on the same
`RowReader` to nest objects across a join, which is how relations work.

### Selectable subsets

A `@Queryable` class that maps only *some* of a table's columns is the "Selectable" case: the generator emits
a **select-narrowing `xQuery`** getter that `SELECT`s exactly those columns (not `SELECT *`):

```dart
@Queryable(Users.table)
class UserSummary {
  final int id;
  final String name;
  const UserSummary(this.id, this.name);
}

// userSummaryQuery == from(Users.table).select([Users.id, Users.name]).map($UserSummaryFromRow)
final summaries = await db.fetch(userSummaryQuery);
```

(Classes with `@Relation`s get the join-based `xQuery` instead — see below.)

Any `@Queryable` class that maps a `PrimaryKey` column also gets a bare `findX(pk)` — a type-safe
find-by-primary-key that composes `xQuery` with `findBy`:

```dart
final user = await findUser(1).first(db); // MappedQuery<User>, filtered by Users.id == 1
```

## `@Relation` (read-side joins)

```dart
@Queryable(Posts.table)
class Post {
  final int id; final String title; final int views;
  @Relation(Posts.authorId, depth: 2) final User? author;   // author + author's manager
  const Post({required this.id, required this.title, required this.views, this.author});
}
```

- The field must be a **nullable, optional named** parameter whose type is another `@Queryable` class.
- `depth: n` unrolls the join `n` levels deep with path-based aliases (`author`, `author_manager`, …), so
  self-referential and cyclic relations terminate safely.
- The generator emits a self-mapping query getter (named like the mapper, e.g. `postQuery`) that wires the
  joins, aliases, and nested decoding, and is still a chainable `MappedQuery`:

```dart
final posts = await db.fetch(postQuery.orderBy(Posts.views.desc()));
// each Post has .author, and .author.manager, populated.
```

Nullable FKs use `LEFT JOIN` (rows without a relation still come back, with `null`); non-null FKs use
`INNER JOIN`. Relations are read-only: the write derives (`toInsert`/`toUpdate`) skip them, so include the
raw FK as its own field (e.g. `managerId`) if you need to write it.

## `@Insertable` / `@AsChangeset` output

```dart
@Insertable(Users.table)
@AsChangeset(Users.table)
class User { /* … */ }
```

```dart
await db.execute(user.toInsert());                          // INSERT all writable columns
await db.execute(user.toUpdate().where(Users.id.eq(user.id)));  // UPDATE … SET …; you add the WHERE
```

`toUpdate()` builds only the `SET` clause; append `.where(...)` yourself (typically on the primary key). Both
skip `readOnly` columns and `@Relation` fields.
