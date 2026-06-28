# diesel_codegen

`build_runner` / `source_gen` code generation for [diesel_dart](../../README.md) — the Dart analog of
diesel-rs's `#[derive(...)]` macros. It derives row mappers and write statements from the annotations in
[`package:diesel`](../diesel).

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
dart run build_runner build
```

The builder emits a `SharedPartBuilder`, so all generated code for a file lands in one `<file>.g.dart`. Three
generators run — `QueryableGenerator`, `InsertableGenerator`, `AsChangesetGenerator` — and a class may carry
any combination of the annotations.

## What it generates

| Annotation | Output |
|---|---|
| `@Queryable(table)` | `$XFromRow` reader, `const xMapper = RowMapper<X>(…)`, and (with `@Relation`) a `xQuery` join getter |
| `@Insertable(table)` | `extension XInsert on X { InsertStatement<T> toInsert() }` |
| `@AsChangeset(table)` | `extension XChangeset on X { UpdateStatement<T> toUpdate() }` (SET clause only) |
| `@Column(col, {readOnly, writeOnly})` | field → column mapping and read/write direction |
| `@Relation(fk, {depth})` | a joined, nested related object (read-side), unrolled `depth` levels with path aliases |

Fields map to columns by name (camelCase ↔ snake_case) unless `@Column` overrides. `readOnly` reads but isn't
written; `writeOnly` is written but not read (the field must be optional); setting both is a generation error.
Relation fields must be nullable, optional, and named.

Full details and examples: the [derives guide](../../docs/derives.md).

## Internals

The pipeline is `EdgeAnalyzer` (analyzer elements → a plain model) → pure string **emitters**
(`reader_emitter`, `insert_emitter`, `changeset_emitter`, relation emitters) → the generators. Emitters are
pure functions, unit-tested under `test/` without the analyzer; generators are thin analyzer bridges. See
[CLAUDE.md](../../CLAUDE.md) for how to add a new derive.
