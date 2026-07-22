# basalt_postgres

![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5-0175C2?logo=dart&logoColor=white)
![Driver](https://img.shields.io/badge/driver-postgres_v3-336791?logo=postgresql&logoColor=white)
![Part of](https://img.shields.io/badge/part_of-basalt__dart-informational)

**The Postgres backend for [basalt_dart](../../README.md)** — a concrete `SqlDialect` and a
[`package:postgres`](https://pub.dev/packages/postgres) (v3)-backed `Connection`. The *same* typed query
DSL, schema, and migrations run on Postgres and [`basalt_sqlite`](../basalt_sqlite) unchanged; verified
end-to-end against **Postgres 16**.

## Contents

- [Status](#status)
- [Install](#install)
- [Opening a connection](#opening-a-connection)
- [Dialect](#dialect)
- [Introspection & the CLI](#introspection--the-cli)
- [Native types](#native-types)
- [Running the tests](#running-the-tests)

## Status

| | Feature |
|---|---|
| ✅ | `PostgresDialect` — numbered `$N` placeholders (1-based), double-quoted identifiers |
| ✅ | `PostgresConnection` — the full `Connection` interface (`fetch`, `execute`, `executeReturning`, `executeSql`, `queryRaw`, `transaction` with savepoints, `introspect`, `close`) |
| ✅ | Introspection via `information_schema` (tables, columns, nullability, primary & foreign keys) for `generate-schema` |
| ✅ | CLI `postgres://` wiring + cross-backend codecs (`int`/`text`/`real`/`bool`/`DateTime`) |
| ✅ | Native PG type codecs (`json`/`jsonb`, `uuid`, `numeric`, arrays) via the adapter's `native_types` preset |

## Install

```yaml
dependencies:
  basalt:
  basalt_postgres:
```

## Opening a connection

`PostgresConnection.open` is an async factory (it negotiates the connection up front):

```dart
import 'package:basalt/basalt.dart';
import 'package:basalt_postgres/basalt_postgres.dart';

final db = await PostgresConnection.open(
  host: 'localhost', port: 5432, database: 'app',
  username: 'postgres', password: 'postgres', ssl: false,
);

final adults = await from(Users.table)
    .where(Users.age > 18)
    .map(userMapper.read)
    .load(db);           // basalt-style terminal; same as db.fetch(...)

await db.close();
```

Everything else — the query DSL, `@Queryable`/`@Insertable` codegen, migrations — is identical to the
SQLite examples in the [root README](../../README.md) and
[packages/basalt/doc/queries.md](../basalt/doc/queries.md).

## Dialect

`PostgresDialect` quotes identifiers with double quotes and emits numbered placeholders (`$1`, `$2`, …).
Values are passed natively (no `bool → int` / `DateTime → epoch` adaptation — Postgres has real `boolean`
and `timestamp`), while decoders stay lenient so the same Dart types round-trip on both backends.

## Introspection & the CLI

`introspect()` reads `information_schema` into the dialect-neutral `List<IntrospectedTable>` model. The
`basalt` CLI selects this backend from a `postgres://` / `postgresql://` `database_url`, so
`migration run` and `generate-schema` work against Postgres:

```yaml
# basalt.yaml
database_url: postgres://postgres:postgres@localhost:5432/app?sslmode=disable
```

## Native types

Beyond the cross-backend codecs (`int`/`text`/`real`/`bool`/`DateTime`), the adapter ships
Postgres-native codecs, opted into per project with `native_types: true` in the `types:` block of
`basalt.yaml`. With it enabled, `generate-schema` maps native columns to:

| Postgres | Dart | Codec |
|---|---|---|
| `json` / `jsonb` | `Map<String, Object?>` | `PostgresJsonbSqlType` |
| `uuid` | `String` | `PostgresUuidSqlType` |
| `numeric` / `decimal` | `String` (exact, not a lossy `double`) | `PostgresNumericSqlType` |
| `integer[]` / `bigint[]` | `List<int>` | `PostgresArraySqlType<int>` |
| `double precision[]` / `real[]` | `List<double>` | `PostgresArraySqlType<double>` |
| `boolean[]` | `List<bool>` | `PostgresArraySqlType<bool>` |
| `text[]` / `varchar[]` / `uuid[]` / `numeric[]` | `List<String>` | `PostgresArraySqlType<String>` |

```dart
// hand-written or generated with `native_types: true`
static const tags =
    ValueColumn<List<String>, Posts>(table, 'tags', PostgresArraySqlType<String>());
static const amount =
    ValueColumn<String, Posts>(table, 'amount', PostgresNumericSqlType());
```

A schema using these codecs imports `package:basalt_postgres` and is no longer backend-portable.
Without the preset, `uuid` falls back to `String`, `numeric` to `double`, and arrays are unmapped.

## Running the tests

The connection tests need a Postgres server; the suite **skips gracefully** if none is reachable.

```sh
docker run -d --name basalt_pg \
  -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=basalt_test -p 5433:5432 postgres:16
cd packages/basalt_postgres && dart test
```

Override the endpoint with `BASALT_PG_HOST` / `BASALT_PG_PORT` (defaults `localhost:5433`).
