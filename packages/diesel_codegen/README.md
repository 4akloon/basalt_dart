# diesel_codegen

![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5-0175C2?logo=dart&logoColor=white)
![Builder](https://img.shields.io/badge/build__runner-source__gen-blueviolet)
![Part of](https://img.shields.io/badge/part_of-diesel__dart-informational)

**`build_runner` / `source_gen` code generation for [diesel_dart](../../README.md)** — the Dart analog of
diesel-rs's `#[derive(...)]` macros. It derives row mappers, self-mapping join queries, and `INSERT`/`UPDATE`
builders from the annotations in [`package:diesel`](../diesel).

## Contents

- [Setup](#setup)
- [What it generates](#what-it-generates)
- [Field mapping](#field-mapping)
- [A worked example](#a-worked-example)
- [How it works](#how-it-works)

## Setup

```yaml
dev_dependencies:
  diesel_codegen:
  build_runner: ^2.4.0
```

Add a `part` directive next to your annotated classes and run the builder:

```dart
import 'package:diesel/diesel.dart';
import 'schema.dart';

part 'user.g.dart';
```

```sh
dart run build_runner build          # one-shot
dart run build_runner watch          # rebuild on change
```

The builder is a `SharedPartBuilder`, so all generated code for a file lands in one `<file>.g.dart`. Three
generators run — `QueryableGenerator`, `InsertableGenerator`, `AsChangesetGenerator` — and a class may carry
any combination of the annotations.

## What it generates

| Annotation | Output |
|---|---|
| `@Queryable(table)` | `$XFromRow` reader, `const xMapper = RowMapper<X>(…)`, an `xQuery` getter, and a bare `findX(pk)` when the class maps a `PrimaryKey` |
| `@Insertable(table)` | `extension XInsert on X { InsertStatement<T> toInsert() }` |
| `@AsChangeset(table)` | `extension XChangeset on X { UpdateStatement<T> toUpdate() }` (the `SET` clause; you append `.where(...)`) |
| `@Column(col, {readOnly, writeOnly})` | field → column mapping and read/write direction |
| `@Relation(fk, {depth})` | a joined, nested related object (read-side), unrolled `depth` levels with path aliases |

For a class *with* `@Relation`s, `xQuery` is a **self-mapping join query** — it wires up the joins, table
aliases, and nested decoding for you and is still a chainable `MappedQuery`. For a class *without* relations,
`xQuery` narrows the projection to exactly that class's columns (the "Selectable" analog).

## Field mapping

- Fields map to columns **by name** (camelCase ↔ snake_case) unless `@Column(SomeTable.col)` overrides.
- `readOnly` — read on SELECT, skipped on write (autoincrement PKs, server defaults).
- `writeOnly` — written but skipped by the row reader (the field must be optional so its default is used).
- Setting both is a generation error — a field that's neither read nor written isn't a column; use a getter.
- `@Relation` fields must be **nullable, optional, and named**; the write derives skip them.

Full details and edge cases: the [derives guide](../../docs/derives.md).

## A worked example

```dart
@Queryable(Users.table)
@Insertable(Users.table)
@AsChangeset(Users.table)
class User {
  final int id;
  final String name;
  final int age;
  @Relation(Users.managerId, depth: 2) // self-join, nested two levels
  final User? manager;
  const User(this.id, this.name, this.age, {this.manager});
}
```

generates (abridged) `user.g.dart`:

```dart
User $UserFromRow(RowReader r, [QuerySource<Users> src = Users.table, ...]) =>
    User(r.get(src.col(Users.id)), r.get(src.col(Users.name)), r.get(src.col(Users.age)),
         manager: /* nested join, alias-safe */);

const userMapper = RowMapper<User>($UserFromRow);
MappedQuery<User> get userQuery { /* leftJoin the manager, map */ }
MappedQuery<User> findUser(int id) => userQuery.findBy(Users.id, id);
```

See [`example/`](../../example) for a complete two-file model (cross-file `@Relation`) and its generated output.

## How it works

The pipeline is small and layered:

```
EdgeAnalyzer (analyzer elements → a plain model)
      → pure string emitters (reader_emitter, insert_emitter, changeset_emitter, relation emitters)
      → generators (thin GeneratorForAnnotation bridges) registered in builder.dart
```

Emitters are **pure functions**, unit-tested under `test/` without the analyzer; the generators are thin
analyzer bridges. To add a new derive, add the annotation in `package:diesel`, a `TypeChecker` + parsing in
`edge_analyzer.dart`, a pure emitter, a `GeneratorForAnnotation`, and register it in `builder.dart`. See
[CLAUDE.md](../../CLAUDE.md).
