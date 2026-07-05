import 'aggregate_query_emitter.dart';
import 'find_emitter.dart';
import 'has_many_fold_emitter.dart';
import 'has_many_query_emitter.dart';
import 'naming.dart';
import 'query_getter_emitter.dart';
import 'queryable_model.dart';
import 'reader_emitter.dart';
import 'relation_call_emitter.dart';
import 'relation_edge.dart';
import 'relation_tree_builder.dart';
import 'select_query_emitter.dart';

/// Generates reader/mapper/query code from a resolved [QueryableModel].
///
/// Each class emits exactly one public `$ClassFromRow` reader (plus its mapper
/// and, when it has relations, a query getter). Relation targets are read via
/// their own public readers — imported from wherever they are defined — so
/// nothing is regenerated per consumer. That is what keeps split-file models
/// free of duplicated reader functions.
final class ModelCodeGenerator {
  const ModelCodeGenerator({
    this.readerEmitter = const ReaderEmitter(),
    this.queryGetterEmitter = const QueryGetterEmitter(),
    this.relationCalls = const RelationCallEmitter(),
    this.selectQueryEmitter = const SelectQueryEmitter(),
    this.findEmitter = const FindEmitter(),
    this.hasManyQueryEmitter = const HasManyQueryEmitter(),
    this.hasManyFoldEmitter = const HasManyFoldEmitter(),
    this.aggregateQueryEmitter = const AggregateQueryEmitter(),
  });
  final ReaderEmitter readerEmitter;
  final QueryGetterEmitter queryGetterEmitter;
  final RelationCallEmitter relationCalls;
  final SelectQueryEmitter selectQueryEmitter;
  final FindEmitter findEmitter;
  final HasManyQueryEmitter hasManyQueryEmitter;
  final HasManyFoldEmitter hasManyFoldEmitter;
  final AggregateQueryEmitter aggregateQueryEmitter;

  List<String> generate(QueryableModel model) {
    final root = model.root;
    final infos = model.classInfos;
    final className = root.className;
    final readerName = '\$${className}FromRow';
    final units = <String>[];

    if (root.aggregateInfo case final agg?) {
      units.add(
        aggregateQueryEmitter.emit(
          className: className,
          queryName: '${lowerFirst(className)}Query',
          info: agg,
        ),
      );
      return units;
    }

    bool hasRelations(String cls) =>
        (infos[cls]?.ownEdges ?? const <RelationEdge>[]).isNotEmpty;

    units.add(
      readerEmitter.emit(
        className: className,
        readerName: readerName,
        tableMarker: root.tableMarker,
        columnArgs: root.columnArgs,
        relationArgs: relationCalls.forReader(root.ownEdges, hasRelations),
      ),
    );
    units.add(
      'const ${lowerFirst(className)}Mapper = RowMapper<$className>($readerName);',
    );

    final queryName = '${lowerFirst(className)}Query';
    final foldName = '\$${className}Fold';

    if (root.hasManyEdges.isNotEmpty) {
      units.add(
        hasManyFoldEmitter.emit(root: root, classInfos: infos),
      );
      units.add(
        hasManyQueryEmitter.emit(
          root: root,
          classInfos: infos,
          queryName: queryName,
          foldName: foldName,
        ),
      );
    } else if (root.ownEdges.isNotEmpty) {
      List<RelationEdge> edgesOf(String cls) =>
          infos[cls]?.ownEdges ?? const <RelationEdge>[];
      final treeNodes = RelationTreeBuilder(edgesOf).unrollRoots(root.ownEdges);
      final seedBudget =
          root.ownEdges.map((e) => e.depth).reduce((a, b) => a > b ? a : b);

      units.add(
        queryGetterEmitter.emit(
          className: className,
          queryName: queryName,
          tableMarker: root.tableMarker,
          readerName: readerName,
          seedBudget: seedBudget,
          treeNodes: treeNodes,
        ),
      );
    } else {
      units.add(
        selectQueryEmitter.emit(
          className: className,
          queryName: queryName,
          tableMarker: root.tableMarker,
          readerName: readerName,
          columnArgs: root.columnArgs,
        ),
      );
    }

    if (root.pkColumnExpr case final pkExpr? when root.pkType != null) {
      units.add(
        findEmitter.emit(
          className: className,
          findName: 'find$className',
          queryName: queryName,
          pkColumnExpr: pkExpr,
          pkType: root.pkType!,
          foldQuery: root.hasManyEdges.isNotEmpty,
        ),
      );
    }

    return units;
  }
}

/// Convenience for callers that want a single chunk (e.g. tests).
extension ModelCodeGeneratorJoin on ModelCodeGenerator {
  String generateSource(QueryableModel model) => generate(model).join('\n\n');
}
