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

Or via the CLI — select the backend and describe the connection in
`basalt.yaml` (add `basalt_postgres` to `dev_dependencies`):

```yaml
backend: basalt_postgres
database:
  url: postgres://user:pass@localhost:5432/mydb?sslmode=disable
```

or with manual keys instead of a URL:

```yaml
backend: basalt_postgres
database:
  host: localhost       # default: localhost
  port: 5432            # default: 5432
  database: mydb        # required
  username: user        # default: postgres
  password: pass        # default: empty
  ssl: false            # default: true
```

`PostgresAdapter` (exposed via `package:basalt_postgres/adapter.dart`)
interprets these options, powers `database reset` (drops and recreates the
`public` schema), and ships a `native_types: true` preset that maps
`json`/`jsonb` columns to `Map<String, Object?>` via `PostgresJsonbSqlType` in
`generate-schema` — note a schema using it imports this package and is no
longer backend-portable.

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
