# Type mapping

`SqlType<T>` defines how a Dart value is `encode`d into a driver parameter and `decode`d back. The built-in
instances are `const` (which is what lets columns be `static const` and usable in annotations).

## Built-in types (SQLite backend)

| `SqlType` | Dart `T` | SQLite storage | Notes |
|---|---|---|---|
| `SqlType.integer` | `int` | `INTEGER` | |
| `SqlType.text` | `String` | `TEXT` | |
| `SqlType.real` | `double` | `REAL` | |
| `SqlType.boolean` | `bool` | `INTEGER` | `true`→`1`, `false`→`0`; any non-zero decodes to `true`. |
| `SqlType.blob` | `List<int>` | `BLOB` | |
| `SqlType.dateTime` | `DateTime` | `INTEGER` | Stored as epoch milliseconds (sortable, timezone-free). |

## Nullable variants

For columns that allow `NULL`, use the `*OrNull` variants — the column type becomes `T?`:

`SqlType.integerOrNull`, `textOrNull`, `realOrNull`, `booleanOrNull`, `blobOrNull`, `dateTimeOrNull`.

Their decoders map a `NULL` row value to `null`. The **non-null** decoders intentionally throw on `NULL`,
which surfaces an unexpected `NULL` in a column you declared non-nullable. This is purely additive — the
`RowReader` and serializer are unchanged.

For null **predicates**, use `col.isNull()` / `col.isNotNull()` (an `eq(null)` would emit `= NULL`, which is
never true in SQL).

## SQLite caveats

SQLite has no native boolean or timestamp type. As a result:

- A `bool` column is declared `INTEGER`; introspection (`print-schema`) can't distinguish it from a plain
  integer, so a generated boolean-ish column comes back as `int` (`active` in the example). You can still use
  `SqlType.boolean` when you hand-write or adjust the schema.
- `DateTime` is stored as `INTEGER` epoch milliseconds by `SqlType.dateTime`.

The canonical introspection model (`ColumnType { integer, text, real, boolean, blob, dateTime }`) maps these
uniformly, so a future Postgres backend — which *does* have native `bool`/`timestamp` — will yield `bool` /
`DateTime` directly.

## Custom type codecs

A registry for custom/enum codecs (the analog of diesel-rs `ToSql`/`FromSql`) is not implemented yet; see
[ROADMAP M4](ROADMAP.md). Today, model a custom type by choosing the closest built-in `SqlType` and
converting at the edges of your data classes.
