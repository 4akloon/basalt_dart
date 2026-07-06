import 'aggregate_query_emitter.dart';
import 'has_many_fold_emitter.dart';
import 'has_many_query_emitter.dart';
import 'query_getter_emitter.dart';
import 'queryable_model.dart';
import 'reader_emitter.dart';
import 'relation_call_emitter.dart';
import 'relation_edge.dart';
import 'relation_tree_builder.dart';
import 'select_query_emitter.dart';

/// Generates the `${Class}Query` companion from a resolved [QueryableModel].
///
/// Each `@Queryable` class gets exactly one companion class that *is* the
/// canonical query (`extends MappedQuery`/`FoldMappedQuery`) and carries the
/// public `static fromRow` reader (plus `mapper`, and `fold` for `@HasMany`
/// roots). Relation targets are read via their own `TargetQuery.fromRow` —
/// imported from wherever they are defined — so nothing is regenerated per
/// consumer. That is what keeps split-file models free of duplicated readers.
final class ModelCodeGenerator {
  const ModelCodeGenerator({
    this.readerEmitter = const ReaderEmitter(),
    this.queryGetterEmitter = const QueryGetterEmitter(),
    this.relationCalls = const RelationCallEmitter(),
    this.selectQueryEmitter = const SelectQueryEmitter(),
    this.hasManyQueryEmitter = const HasManyQueryEmitter(),
    this.hasManyFoldEmitter = const HasManyFoldEmitter(),
    this.aggregateQueryEmitter = const AggregateQueryEmitter(),
  });
  final ReaderEmitter readerEmitter;
  final QueryGetterEmitter queryGetterEmitter;
  final RelationCallEmitter relationCalls;
  final SelectQueryEmitter selectQueryEmitter;
  final HasManyQueryEmitter hasManyQueryEmitter;
  final HasManyFoldEmitter hasManyFoldEmitter;
  final AggregateQueryEmitter aggregateQueryEmitter;

  List<String> generate(QueryableModel model) {
    final root = model.root;
    final infos = model.classInfos;
    final className = root.className;

    if (root.aggregateInfo case final agg?) {
      return [
        _companion(
          className: className,
          extendsClause: 'MappedQuery<$className>',
          members: [
            aggregateQueryEmitter.emit(className: className, info: agg),
          ],
        ),
      ];
    }

    bool hasRelations(String cls) =>
        (infos[cls]?.ownEdges ?? const <RelationEdge>[]).isNotEmpty;

    final members = <String>[];
    final String extendsClause;
    List<String> accClasses = const [];

    if (root.hasManyEdges.isNotEmpty) {
      extendsClause = 'FoldMappedQuery<$className>';
      members.add(
        hasManyQueryEmitter.emit(root: root, classInfos: infos),
      );
    } else if (root.ownEdges.isNotEmpty) {
      extendsClause = 'MappedQuery<$className>';
      List<RelationEdge> edgesOf(String cls) =>
          infos[cls]?.ownEdges ?? const <RelationEdge>[];
      final treeNodes = RelationTreeBuilder(edgesOf).unrollRoots(root.ownEdges);
      final seedBudget =
          root.ownEdges.map((e) => e.depth).reduce((a, b) => a > b ? a : b);

      members.add(
        queryGetterEmitter.emit(
          className: className,
          tableMarker: root.tableMarker,
          seedBudget: seedBudget,
          treeNodes: treeNodes,
        ),
      );
    } else {
      extendsClause = 'MappedQuery<$className>';
      members.add(
        selectQueryEmitter.emit(
          className: className,
          tableMarker: root.tableMarker,
          columnArgs: root.columnArgs,
        ),
      );
    }

    members.add(
      readerEmitter.emit(
        className: className,
        tableMarker: root.tableMarker,
        columnArgs: root.columnArgs,
        relationArgs: relationCalls.forReader(root.ownEdges, hasRelations),
      ),
    );
    members.add(
      '  /// Reusable row mapper: `from(t).mapWith(${className}Query.mapper)`.\n'
      '  static const mapper = RowMapper<$className>(fromRow);\n',
    );

    if (root.hasManyEdges.isNotEmpty) {
      final foldCode = hasManyFoldEmitter.emit(root: root, classInfos: infos);
      members.add(foldCode.foldMember);
      accClasses = foldCode.accClasses;
    }

    return [
      _companion(
        className: className,
        extendsClause: extendsClause,
        members: members,
      ),
      ...accClasses,
    ];
  }

  String _companion({
    required String className,
    required String extendsClause,
    required List<String> members,
  }) =>
      '/// Generated read-side query for [$className] — the object *is* the\n'
      '/// query (`db.fetch(${className}Query())`).\n'
      'final class ${className}Query extends $extendsClause {\n'
      '${members.join('\n')}'
      '}\n';
}

/// Convenience for callers that want a single chunk (e.g. tests).
extension ModelCodeGeneratorJoin on ModelCodeGenerator {
  String generateSource(QueryableModel model) => generate(model).join('\n\n');
}
