import 'package:basalt/basalt.dart';

import '../dto/column_dto.dart';
import '../dto/foreign_key_dto.dart';
import '../dto/schema_dto.dart';
import '../dto/table_dto.dart';

/// Introspects a connection's schema into the transport-friendly [SchemaDto].
final class SchemaReader {
  /// Creates a reader over [_conn].
  const SchemaReader(this._conn);

  final Connection _conn;

  /// Introspects every table into a [SchemaDto].
  Future<SchemaDto> read() async =>
      SchemaDto([for (final t in await _conn.introspect()) _table(t)]);

  static TableDto _table(IntrospectedTable t) =>
      TableDto(t.name, [for (final c in t.columns) _column(c)]);

  static ColumnDto _column(IntrospectedColumn c) {
    final fk = c.foreignKey;
    return ColumnDto(
      name: c.name,
      type: c.type.name,
      rawType: c.rawType,
      isNullable: c.isNullable,
      isPrimaryKey: c.isPrimaryKey,
      foreignKey: fk == null ? null : ForeignKeyDto(fk.table, fk.column),
    );
  }
}
