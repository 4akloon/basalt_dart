# Getting Started

`basalt_codegen` is a `build_runner`/`source_gen` generator that derives row
mappers and write statements for your data classes from the annotations in
`package:basalt`.

## Dependencies

```yaml
dev_dependencies:
  basalt_codegen:
  build_runner: ^2.4.0
```

## Wire into build.yaml

The package ships a `build.yaml` that auto-applies to dependents. If you need
an explicit entry:

```yaml
targets:
  $default:
    builders:
      basalt_codegen|queryable:
        enabled: true
```

The builder is `queryableBuilder` — a `SharedPartBuilder` that registers
`QueryableGenerator`, `InsertableGenerator`, and `AsChangesetGenerator`.
Generated code lands in `<file>.g.dart` alongside your model classes.

## Usage

Annotate your model classes and add a `part` directive:

```dart
import 'package:basalt/basalt.dart';
import 'schema.dart';

part 'user.g.dart';

@Queryable(Users.table)
@Insertable(Users.table)
class User {
  final int id;
  final String name;
  const User(this.id, this.name);
}
```

Run:

```sh
dart run build_runner build
```

## What gets generated

| Annotation | Generator | Output |
|---|---|---|
| `@Queryable` | `QueryableGenerator` | `XQuery` companion class — *is* the query (`extends MappedQuery`/`FoldMappedQuery`) and carries `static fromRow`, `static const mapper` and (for `@HasMany`) `static fold` |
| `@Insertable` | `InsertableGenerator` | `toInsert()` extension on the class + a multi-row `toInsert()` extension on `Iterable` of it (one batch `INSERT`) |
| `@AsChangeset` | `AsChangesetGenerator` | `toUpdate()` extension |

For annotation semantics, field mapping, `@Relation` join behavior, and
edge cases, see `basalt` **Annotations & Codegen** — this package implements
that contract; the annotations themselves live in `package:basalt`.
