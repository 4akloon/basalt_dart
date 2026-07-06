# Annotations & Codegen

These annotations mark model classes for `basalt_codegen` (a
`build_runner`/`source_gen` derive) to generate reader/insert/changeset code
from. They're plain data classes here in `basalt` — the generation logic
lives entirely in the `basalt_codegen` package.

## Setup

```yaml
dev_dependencies:
  basalt_codegen:
  build_runner: ^2.4.0
```

```dart
import 'package:basalt/basalt.dart';
import 'schema.dart';

part 'user.g.dart';
```

```sh
dart run build_runner build
```

A class may carry several annotations; each generator contributes its own
(non-overlapping) code to the one `<file>.g.dart`.

## Annotations

| Annotation | Level | Generates |
|---|---|---|
| `@Queryable(table)` | class | an `XQuery` companion class that **is** the query (`extends MappedQuery`/`FoldMappedQuery`; join query when the class has `@Relation`s/`@HasMany`, otherwise a select-narrowing subset query) and carries `static X fromRow(…)`, `static const mapper = RowMapper<X>(fromRow)` and (for `@HasMany` roots) `static fold` |
| `@Insertable(table)` | class | `extension XInsert { InsertStatement<T> toInsert() }` |
| `@AsChangeset(table)` | class | `extension XChangeset { UpdateStatement<T> toUpdate() }` (SET only) |
| `@Column(col, {readOnly, writeOnly})` | field | column mapping + read/write direction |
| `@Relation(fk, {depth})` | field | a joined, nested related object (read-side) |

The class annotations are **independent**: a write-only DTO can be `@Insertable`
alone.

## Field mapping

Each unnamed-constructor parameter maps to a column. By default the field name
selects the column by matching the schema's camelCase accessor (`managerId` →
`Users.managerId`). Override or tune it with `@Column`:

```dart
@Column(Users.name) final String displayName;          // rename: field ≠ column
@Column(Users.id, readOnly: true) final int id;        // read on SELECT, skip INSERT/UPDATE
@Column(Users.token, writeOnly: true) final String? token;  // write, skip row reader
```

- **`readOnly`** — present in the `@Queryable` reader, excluded from `toInsert()`
  and `toUpdate()`'s SET (autoincrement PKs, server defaults).
- **`writeOnly`** — excluded from the row reader (parameter must be optional),
  included in writes.
- Setting **both** is a generation error — use a getter for computed values.

## `@Queryable` output

```dart
@Queryable(Users.table)
class User {
  final int id; final String name; final int age; final int active;
  const User(this.id, this.name, this.age, this.active);
}
```

generates a `UserQuery` companion — an object that *is* the query, plus a
reusable reader/mapper:

```dart
final users = await db.fetch(UserQuery());
// or compose by hand:
final custom = await db.fetch(from(Users.table).mapWith(UserQuery.mapper));
```

The generated `static UserQuery.fromRow` reader is alias-parameterized and
**composable** — it can be called on the same `RowReader` to nest objects
across a join.

> The companion name is `${Class}Query` — avoid hand-writing a class with
> that name next to a `@Queryable` model.

### Selectable subsets

A `@Queryable` class that maps only *some* of a table's columns gets a
**select-narrowing `XQuery`** whose query `SELECT`s exactly those columns:

```dart
@Queryable(Users.table)
class UserSummary {
  final int id;
  final String name;
  const UserSummary(this.id, this.name);
}

// UserSummaryQuery() selects only [Users.id, Users.name] and decodes with fromRow.
final summaries = await db.fetch(UserSummaryQuery());
```

(Classes with `@Relation`s get the join-based query instead.)

Find by primary key via the inherited `findBy`:

```dart
final user = await UserQuery().findBy(Users.id, 1).first(db);
```

## `@Relation` (read-side joins)

```dart
@Queryable(Posts.table)
class Post {
  final int id; final String title; final int views;
  @Relation(Posts.authorId, depth: 2) final User? author;
  const Post({required this.id, required this.title, required this.views, this.author});
}
```

- The field must be a **nullable, optional named** parameter whose type is
  another `@Queryable` class.
- `depth: n` unrolls the join `n` levels deep with path-based aliases
  (`author`, `author_manager`, …), so cyclic relations terminate safely.
- The generator emits a self-mapping query class (e.g. `PostQuery`):

```dart
final posts = await db.fetch(PostQuery().orderBy(Posts.views.desc()));
// each Post has .author, and .author.manager, populated.
```

Nullable FKs use `LEFT JOIN`; non-null FKs use `INNER JOIN`. Relations are
read-only — include the raw FK as its own field (e.g. `managerId`) if you
need to write it.

## `@Insertable` / `@AsChangeset` output

```dart
@Insertable(Users.table)
@AsChangeset(Users.table)
class User { /* … */ }
```

```dart
await db.execute(user.toInsert());
await db.execute(user.toUpdate().where(Users.id.eq(user.id)));
```

`toUpdate()` builds only the `SET` clause; append `.where(...)` yourself.
Both skip `readOnly` columns and `@Relation` fields.
