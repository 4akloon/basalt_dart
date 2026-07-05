# Annotations & Codegen

These annotations mark model classes for `basalt_codegen` (a
`build_runner`/`source_gen` derive) to generate reader/insert/changeset code
from. They're plain data classes here in `basalt` — the generation logic
lives entirely in the `basalt_codegen` package, keeping this package free of
an `analyzer`/`build` dependency.

- `Queryable` — generates a typed row reader plus relation-traversal getters
  for a table, from its declared columns and `@Relation` edges.
- `Insertable` — generates a typed `.insertRow()` builder for a table.
- `AsChangeset` — generates a typed changeset (partial-update) builder.
- `Column` — field-level annotation binding a model field to a `static const`
  `TableColumn` (e.g. `@Column(Users.name)`). This is the **field annotation**;
  don't confuse it with the `TableColumn` type hierarchy itself.
- `Relation` — field-level annotation declaring a foreign-key relation to
  traverse (used to emit nested/joined reads).

## Using it

```dart
@Queryable(Users)
class User {
  @Column(Users.id)
  final int id;
  @Column(Users.name)
  final String name;
}
```

Run `dart run build_runner build` in a package with `basalt_codegen` as a
dev dependency to generate the corresponding `*.g.dart` part file.
