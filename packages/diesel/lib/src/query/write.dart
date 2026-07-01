/// Write builders: INSERT / UPDATE / DELETE and their `RETURNING` variants.
///
/// The sealed [WriteStatement] base lives here so the serializer can switch
/// over it exhaustively; each concrete statement (and the `RETURNING` helpers)
/// is a `part` under `writes/`.
library;

import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../schema/table.dart';
import 'query.dart';
import 'row_reader.dart';

part 'writes/delete_statement.dart';
part 'writes/insert_statement.dart';
part 'writes/on_conflict.dart';
part 'writes/returning.dart';
part 'writes/returning_query.dart';
part 'writes/update_statement.dart';
part 'writes/write_returning.dart';

/// Statements that mutate rows and return an affected-row count rather than a
/// result set. Sealed so the serializer can exhaustively switch over them.
sealed class WriteStatement {
  const WriteStatement();
}
