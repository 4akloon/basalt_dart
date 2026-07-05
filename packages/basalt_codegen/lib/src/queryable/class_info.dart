import 'aggregate_info.dart';
import 'column_arg.dart';
import 'has_many_edge.dart';
import 'relation_edge.dart';

/// Everything the code generator needs to know about a single `@Queryable`
/// class, resolved from its element. Collected for the whole relation closure
/// reachable from a generated class so each `.g.dart` is self-contained — it
/// never references generated symbols from another library.
final class ClassInfo {
  const ClassInfo({
    required this.className,
    required this.tableMarker,
    required this.columnArgs,
    this.ownEdges = const [],
    this.hasManyEdges = const [],
    this.aggregateInfo,
    this.pkColumnExpr,
    this.pkType,
    this.pkParamName,
  });
  final String className;
  final String tableMarker;
  final List<ColumnArg> columnArgs;

  /// The class's own `@Relation` edges (its outgoing relations).
  final List<RelationEdge> ownEdges;

  /// The class's own `@HasMany` edges (children loaded in a second batched query).
  final List<HasManyEdge> hasManyEdges;

  /// Non-null when the class is an aggregate `@Queryable` (`@Agg` fields).
  final AggregateInfo? aggregateInfo;

  /// The primary-key column accessor (e.g. `Users.id`) and its Dart value type
  /// (e.g. `int`) when the class maps a `PrimaryKey` column — drives the
  /// generated bare `findX(value)`. Both null when the class has no PK field.
  final String? pkColumnExpr;
  final String? pkType;
  final String? pkParamName;
}
