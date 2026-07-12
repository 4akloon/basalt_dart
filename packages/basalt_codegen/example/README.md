# basalt_codegen example

`basalt_codegen` is a `build_runner` generator — you drive it by annotating classes
and running `build_runner`, not by calling an API. A complete, working setup (models,
generated `*.g.dart`, and repositories) lives in the
[top-level example app](https://github.com/4akloon/basalt_dart/tree/main/example)
(`example/lib/data/models/`).

## Install

```yaml
# pubspec.yaml
dependencies:
  basalt: ^0.0.1

dev_dependencies:
  basalt_codegen: ^0.0.1
  build_runner: ^2.15.0
```

## Annotate

```dart
import 'package:basalt/basalt.dart';

part 'models.g.dart';

// Read model — generates a RowReader-based mapper + typed query getters.
@Queryable()
class User {
  const User(this.id, this.name, this.age);
  final int id;
  final String name;
  final int age;
}

// Write model — generates toInsert().
@Insertable()
class NewUser {
  const NewUser(this.id, this.name, this.age);
  final int id;
  final String name;
  final int age;
}
```

## Generate

```console
$ dart run build_runner build
```

This emits `models.g.dart` with the readers and `INSERT`/`UPDATE` builders. See the
[getting-started guide](https://github.com/4akloon/basalt_dart/tree/main/packages/basalt_codegen/doc/getting_started.md)
for field mapping (`@Column`, `readOnly`/`writeOnly`) and `@Relation`.
