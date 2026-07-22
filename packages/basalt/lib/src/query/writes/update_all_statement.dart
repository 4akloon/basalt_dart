part of '../write.dart';

/// Batch `UPDATE`: one statement that updates many rows with per-row values,
/// joining the target table against a `VALUES` table on the key column(s):
///
/// ```sql
/// WITH "__basalt_values"("id", "stock") AS (VALUES (?, ?), (?, ?))
/// UPDATE "products" SET "stock" = "__basalt_values"."stock"
/// FROM "__basalt_values"
/// WHERE "products"."id" = "__basalt_values"."id"
/// ```
///
/// Build with [updateAll]:
///
/// ```dart
/// await db.execute(
///   updateAll(Products.table).keyedBy(Products.id).values([
///     for (final p in products)
///       [Products.id.set(p.id), Products.stock.set(p.stock)],
///   ]),
/// );
/// ```
///
/// Every row must contain the key column(s); the remaining columns become the
/// `SET` clause. Key values must be unique within one batch — when several
/// `VALUES` rows match the same target row, SQL leaves which one wins
/// undefined. Rows whose key matches nothing update nothing (the affected
/// count only covers matched rows). Values are literals: [TableColumn.set]
/// only — `setExpr`/`setToExcluded` don't fit a `VALUES` tuple.
///
/// Requires SQLite ≥ 3.33 (`UPDATE ... FROM`); any supported Postgres works.
///
/// {@category writes}
final class UpdateAllStatement<Tbl> extends WriteStatement {
  UpdateAllStatement(this.table);
  final String table;

  /// Key column names set via [keyedBy] — the join between the target table
  /// and the `VALUES` table.
  final List<String> keyColumns = [];

  /// Column names, recorded from the first row; every row must use the same
  /// columns in the same order.
  final List<String> columns = [];

  /// Each column's codec (parallel to [columns]) — lets a dialect cast the
  /// `VALUES` parameters when their type can't be inferred (Postgres).
  final List<SqlType<Object?>?> columnTypes = [];

  /// Encoded value tuples — one list per row.
  final List<List<Object?>> rows = [];

  /// Extra predicate ANDed onto the key join (`null` = key join only).
  SqlNode? whereNode;

  /// Declares [key] as a join key. Call once for a single-column key or
  /// repeatedly for a composite key. Every row passed to [values] must
  /// include the key column(s).
  UpdateAllStatement<Tbl> keyedBy(TableColumn<Object?, Tbl> key) {
    keyColumns.add(key.name);
    return this;
  }

  /// Adds rows: each element is one row's assignments (key included). Columns
  /// are taken from the first row; every row must use the same columns in the
  /// same order.
  UpdateAllStatement<Tbl> values(
      Iterable<Iterable<ColumnValue<Tbl>>> valueRows) {
    for (final row in valueRows) {
      final encoded = <Object?>[];
      final recordColumns = columns.isEmpty && rows.isEmpty;
      for (final assignment in row) {
        if (assignment.valueExpr != null || assignment.isExcluded) {
          throw ArgumentError(
            'updateAll rows are literal VALUES: '
            '"${assignment.column}" must be assigned with set(), '
            'not setExpr()/setToExcluded().',
          );
        }
        if (recordColumns) {
          columns.add(assignment.column);
          columnTypes.add(assignment.type);
        }
        encoded.add(assignment.encoded);
      }
      if (encoded.length != columns.length) {
        throw ArgumentError(
          'updateAll row ${rows.length} sets ${encoded.length} column(s), '
          'but the first row set ${columns.length} — every row must use the '
          'same columns in the same order.',
        );
      }
      rows.add(encoded);
    }
    return this;
  }

  /// Extra filter on the target table, ANDed onto the key join — e.g. only
  /// touch rows that are still `active`.
  UpdateAllStatement<Tbl> where(Expression<bool, Tbl> predicate) {
    whereNode = predicate.node;
    return this;
  }
}

/// Starts a batch `UPDATE` of [table] — see [UpdateAllStatement].
///
/// {@category writes}
UpdateAllStatement<Tbl> updateAll<Tbl>(TableRef<Tbl> table) =>
    UpdateAllStatement(table.tableName);
