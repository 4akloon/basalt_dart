# Getting Started

`basalt_postgres` provides `PostgresConnection` and `PostgresDialect` — the
Postgres backend for `package:basalt`.

## Open a connection

```dart
import 'package:basalt_postgres/basalt_postgres.dart';

final db = await PostgresConnection.open(
  host: 'localhost',
  port: 5432,
  database: 'mydb',
  username: 'user',
  password: 'pass',
  ssl: false,   // local/dev
);
```

Or via the CLI — set `database_url` in `basalt.yaml` to a Postgres URL:

```yaml
database_url: postgres://user:pass@localhost:5432/mydb
```

`ConnectionFactory` in `basalt_cli` opens `PostgresConnection` for
`postgres://` / `postgresql://` schemes.

## Run queries

The same query builder, schema, and generated mappers work unchanged:

```dart
import 'package:basalt/basalt.dart';

final rows = await db.fetch(
  from(Users.table).where(Users.age > 18).mapWith(UserQuery.mapper),
);

await db.close();
```

## Dialect

`PostgresDialect` uses double-quoted identifiers and numbered `$N` placeholders
(1-based), unlike SQLite's positional `?`. This is the main dialect-level
difference the serializer needs — proof that `QueryBuilder` is backend-agnostic.

`encodeParam` passes `bool` and `DateTime` through natively (no int/epoch
remapping). See `basalt` **Types** for the cross-backend codec model.

## Introspection

`PostgresConnection.introspect()` reads `information_schema` and maps native
Postgres types into the dialect-neutral `IntrospectedTable` model, consumed by
`basalt_cli generate-schema`.
