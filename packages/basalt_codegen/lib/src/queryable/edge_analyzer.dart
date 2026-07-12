import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:basalt/basalt.dart';
import 'package:source_gen/source_gen.dart';

import 'aggregate_info.dart';
import 'aggregate_join.dart';
import 'class_info.dart';
import 'column_arg.dart';
import 'has_many_edge.dart';
import 'naming.dart';
import 'relation_edge.dart';
import 'require_present.dart';

// Match annotations by name within the `basalt` package. This resolves the
// types regardless of whether they are referenced via the `basalt.dart` barrel
// or their defining library (`fromUrl` only matches the defining library).
const queryableChecker = TypeChecker.typeNamed(Queryable, inPackage: 'basalt');
const insertableChecker =
    TypeChecker.typeNamed(Insertable, inPackage: 'basalt');
const asChangesetChecker =
    TypeChecker.typeNamed(AsChangeset, inPackage: 'basalt');
const columnChecker = TypeChecker.typeNamed(Column, inPackage: 'basalt');
const relationChecker = TypeChecker.typeNamed(Relation, inPackage: 'basalt');
const hasManyChecker = TypeChecker.typeNamed(HasMany, inPackage: 'basalt');
const aggChecker = TypeChecker.typeNamed(Agg, inPackage: 'basalt');

/// Top-level so the depth guard is unit-testable without analyzer mocks.
int validateRelationDepth(int depth, Element element) {
  if (depth < 1) {
    throw InvalidGenerationSourceError(
      '@Relation depth must be at least 1 (got $depth).',
      element: element,
    );
  }
  return depth;
}

/// Parses `@Relation` / `@Column` metadata from analyzer elements.
final class EdgeAnalyzer {
  const EdgeAnalyzer();

  RelationEdge parseRelationEdge(
    FieldElement field,
    FormalParameterElement param,
  ) {
    if (param.type.nullabilitySuffix != NullabilitySuffix.question) {
      throw InvalidGenerationSourceError(
        '@Relation field "${param.name}" must be nullable.',
        element: field,
      );
    }

    final paramType = param.type;
    if (paramType is! InterfaceType) {
      throw InvalidGenerationSourceError(
        '@Relation field "${param.name}" must reference a @Queryable class.',
        element: field,
      );
    }
    final targetClass = paramType.element;
    if (!queryableChecker.hasAnnotationOfExact(targetClass)) {
      throw InvalidGenerationSourceError(
        '@Relation target ${targetClass.name} must be @Queryable.',
        element: field,
      );
    }

    final relAnn = requirePresent(
      relationChecker.firstAnnotationOfExact(field),
      'the @Relation annotation',
    );
    final depth = validateRelationDepth(
      relAnn.getField('depth')?.toIntValue() ?? 1,
      field,
    );
    final colObj = relAnn.getField('column');
    if (colObj == null) {
      throw InvalidGenerationSourceError(
        '@Relation(column) must reference a schema FK (e.g. Posts.authorId).',
        element: field,
      );
    }

    final colType = colObj.type;
    if (colType is! InterfaceType || colType.typeArguments.length < 3) {
      throw InvalidGenerationSourceError(
        '@Relation(column) must reference a schema FK (e.g. Posts.authorId).',
        element: field,
      );
    }

    final parentMarker = colType.typeArguments[1].element?.name;
    final targetMarker = colType.typeArguments[2].element?.name;
    final sqlName = colObj.getField('name')?.toStringValue();
    final pkObj = colObj.getField('references');
    final pkSqlName = pkObj?.getField('name')?.toStringValue();

    if (parentMarker == null ||
        targetMarker == null ||
        sqlName == null ||
        pkSqlName == null) {
      throw InvalidGenerationSourceError(
        '@Relation(column) must reference a schema FK (e.g. Posts.authorId).',
        element: field,
      );
    }

    final fkType = colType.typeArguments[0];
    final fkNullable = fkType.nullabilitySuffix == NullabilitySuffix.question;

    return RelationEdge(
      fieldName: requirePresent(param.name, 'the @Relation field name'),
      depth: depth,
      parentMarker: parentMarker,
      fkAccessor: camelCase(sqlName),
      fkNullable: fkNullable,
      targetMarker: targetMarker,
      targetClass:
          requirePresent(targetClass.name, 'the @Relation target class name'),
      pkAccessor: camelCase(pkSqlName),
    );
  }

  HasManyEdge parseHasManyEdge({
    required FieldElement field,
    required FormalParameterElement param,
    required String parentTableMarker,
    required ClassElement parentElement,
  }) {
    final paramType = param.type;
    if (paramType is! InterfaceType || paramType.element.name != 'List') {
      throw InvalidGenerationSourceError(
        '@HasMany field "${param.name}" must be List<ChildRow>.',
        element: field,
      );
    }
    if (paramType.typeArguments.isEmpty) {
      throw InvalidGenerationSourceError(
        '@HasMany field "${param.name}" must be List<ChildRow>.',
        element: field,
      );
    }
    final childType = paramType.typeArguments.first;
    if (childType is! InterfaceType) {
      throw InvalidGenerationSourceError(
        '@HasMany child type must be a @Queryable class.',
        element: field,
      );
    }
    final childClass = childType.element;
    if (!queryableChecker.hasAnnotationOfExact(childClass)) {
      throw InvalidGenerationSourceError(
        '@HasMany child ${childClass.name} must be @Queryable.',
        element: field,
      );
    }

    final ann = requirePresent(
      hasManyChecker.firstAnnotationOfExact(field),
      'the @HasMany annotation',
    );
    final colObj = ann.getField('column');
    if (colObj == null) {
      throw InvalidGenerationSourceError(
        '@HasMany(column) must reference a child FK (e.g. Addresses.customerId).',
        element: field,
      );
    }
    final colType = colObj.type;
    if (colType is! InterfaceType || colType.typeArguments.length < 3) {
      throw InvalidGenerationSourceError(
        '@HasMany(column) must reference a child FK (e.g. Addresses.customerId).',
        element: field,
      );
    }

    final childMarker = colType.typeArguments[1].element?.name;
    final parentMarker = colType.typeArguments[2].element?.name;
    final sqlName = colObj.getField('name')?.toStringValue();
    final pkObj = colObj.getField('references');
    final pkSqlName = pkObj?.getField('name')?.toStringValue();
    final pkMarker = switch (pkObj?.type) {
      final InterfaceType pkType => pkType.typeArguments[1].element?.name,
      _ => null,
    };

    if (childMarker == null ||
        parentMarker == null ||
        sqlName == null ||
        pkSqlName == null ||
        pkMarker == null) {
      throw InvalidGenerationSourceError(
        '@HasMany(column) must reference a child FK (e.g. Addresses.customerId).',
        element: field,
      );
    }

    if (parentMarker != parentTableMarker) {
      throw InvalidGenerationSourceError(
        '@HasMany($childMarker.${camelCase(sqlName)}) must reference a FK '
        'to $parentTableMarker (got $parentMarker).',
        element: field,
      );
    }

    final childFkColumnExpr = '$childMarker.${camelCase(sqlName)}';
    final parentPkColumnExpr = '$parentMarker.${camelCase(pkSqlName)}';
    final childFkParamName = _fkParamNameOnChild(
      childClass as ClassElement,
      childFkColumnExpr,
      field,
    );

    return HasManyEdge(
      fieldName: requirePresent(param.name, 'the @HasMany field name'),
      childClass:
          requirePresent(childClass.name, 'the @HasMany child class name'),
      childMarker: childMarker,
      childFkColumnExpr: childFkColumnExpr,
      childFkParamName: childFkParamName,
      parentPkColumnExpr: parentPkColumnExpr,
      parentPkParamName: _parentPkParamName(parentElement, parentPkColumnExpr),
    );
  }

  String _fkParamNameOnChild(
    ClassElement child,
    String fkColumnExpr,
    FieldElement field,
  ) {
    final info = describe(child);
    for (final arg in info.columnArgs) {
      if (arg.columnExpr == fkColumnExpr) return arg.paramName;
    }
    throw InvalidGenerationSourceError(
      'Child ${child.name} has no constructor field mapped to $fkColumnExpr.',
      element: field,
    );
  }

  String _parentPkParamName(ClassElement parent, String pkColumnExpr) {
    final ctor = parent.unnamedConstructor;
    if (ctor == null) {
      throw StateError('${parent.name} has no unnamed constructor.');
    }
    final tableMarker = requirePresent(
      tableMarkerOf(parent),
      'the table marker for ${parent.name}',
    );
    for (final param in ctor.formalParameters) {
      final name = param.name;
      final f = name == null ? null : parent.getField(name);
      final arg =
          parseColumnArg(param: param, field: f, tableMarker: tableMarker);
      if (arg.columnExpr == pkColumnExpr) return arg.paramName;
    }
    throw StateError('$pkColumnExpr not mapped on ${parent.name}.');
  }

  ColumnArg parseColumnArg({
    required FormalParameterElement param,
    required FieldElement? field,
    required String tableMarker,
  }) {
    final ann =
        field == null ? null : columnChecker.firstAnnotationOfExact(field);
    final readOnly = ann?.getField('readOnly')?.toBoolValue() ?? false;
    final writeOnly = ann?.getField('writeOnly')?.toBoolValue() ?? false;
    if (readOnly && writeOnly) {
      throw InvalidGenerationSourceError(
        '@Column on "${param.name}" cannot be both readOnly and writeOnly — '
        'a field that is neither read nor written is not a column; use a getter.',
        element: field,
      );
    }

    final colObj = ann?.getField('column');
    if (colObj != null) {
      final colType = colObj.type;
      if (colType is! InterfaceType || colType.typeArguments.length < 2) {
        throw InvalidGenerationSourceError(
          '@Column(column) must reference a schema column '
          '(e.g. Posts.authorId).',
          element: field,
        );
      }
      final marker = colType.typeArguments[1].element?.name;
      final sqlName = colObj.getField('name')?.toStringValue();
      if (marker == null || sqlName == null) {
        throw InvalidGenerationSourceError(
          '@Column(column) must reference a schema column '
          '(e.g. Posts.authorId).',
          element: field,
        );
      }
      return ColumnArg(
        paramName: requirePresent(param.name, 'a @Column parameter name'),
        isNamed: param.isNamed,
        columnExpr: '$marker.${camelCase(sqlName)}',
        readOnly: readOnly,
        writeOnly: writeOnly,
      );
    }

    return ColumnArg(
      paramName: requirePresent(param.name, 'a column parameter name'),
      isNamed: param.isNamed,
      columnExpr: '$tableMarker.${param.name}',
      readOnly: readOnly,
      writeOnly: writeOnly,
    );
  }

  /// The table marker (e.g. `Users`) from a class-level table annotation
  /// (`@Queryable`/`@Insertable`/`@AsChangeset`), selected by [checker].
  String? tableMarkerOf(
    ClassElement element, [
    TypeChecker checker = queryableChecker,
  ]) {
    final ann = checker.firstAnnotationOfExact(element);
    if (ann == null) return null;
    final tableType = ConstantReader(ann).read('table').objectValue.type;
    if (tableType is! InterfaceType) return null;
    return tableType.typeArguments.first.element?.name;
  }

  /// Column args for a write derive (`@Insertable`/`@AsChangeset`): every
  /// constructor parameter mapped to a column, skipping `@Relation` fields
  /// (relations are read-side only).
  List<ColumnArg> writeColumnArgs(ClassElement element, String tableMarker) {
    final constructor = element.unnamedConstructor;
    if (constructor == null) {
      throw InvalidGenerationSourceError(
        '${element.name} needs an unnamed constructor for write generation.',
        element: element,
      );
    }
    final args = <ColumnArg>[];
    for (final param in constructor.formalParameters) {
      final name = param.name;
      final field = name == null ? null : element.getField(name);
      if (field != null && relationChecker.hasAnnotationOfExact(field)) {
        continue;
      }
      if (field != null && hasManyChecker.hasAnnotationOfExact(field)) {
        continue;
      }
      args.add(
        parseColumnArg(param: param, field: field, tableMarker: tableMarker),
      );
    }
    return args;
  }

  /// Resolves a `@Queryable` class element into the data the generator needs.
  /// Works for any element regardless of which library it lives in.
  ClassInfo describe(ClassElement element) {
    final tableMarker = tableMarkerOf(element);
    if (tableMarker == null) {
      throw InvalidGenerationSourceError(
        '@Queryable(table) must reference a TableRef (e.g. Posts.table).',
        element: element,
      );
    }
    final constructor = element.unnamedConstructor;
    if (constructor == null) {
      throw InvalidGenerationSourceError(
        '${element.name} needs an unnamed constructor to be @Queryable.',
        element: element,
      );
    }

    final markerElement = _markerElement(element);
    final columnArgs = <ColumnArg>[];
    final ownEdges = <RelationEdge>[];
    final hasManyEdges = <HasManyEdge>[];
    final aggregates = <AggregateField>[];
    String? pkColumnExpr;
    String? pkType;
    String? pkParamName;
    for (final param in constructor.formalParameters) {
      final name = param.name;
      final field = name == null ? null : element.getField(name);

      if (field != null && relationChecker.hasAnnotationOfExact(field)) {
        _requireNamedOptional(param, field);
        ownEdges.add(parseRelationEdge(field, param));
        continue;
      }
      if (field != null && hasManyChecker.hasAnnotationOfExact(field)) {
        _requireNamedOptional(param, field, kind: 'HasMany');
        hasManyEdges.add(
          parseHasManyEdge(
            field: field,
            param: param,
            parentTableMarker: tableMarker,
            parentElement: element,
          ),
        );
        continue;
      }
      if (field != null && aggChecker.hasAnnotationOfExact(field)) {
        aggregates.add(parseAggregateField(field, param));
        continue;
      }
      final arg =
          parseColumnArg(param: param, field: field, tableMarker: tableMarker);
      if (arg.writeOnly && field != null) {
        _requireOptional(param, field, 'writeOnly');
      }
      columnArgs.add(arg);

      if (pkColumnExpr == null && !arg.writeOnly) {
        final valueType = _primaryKeyType(param, field, markerElement);
        if (valueType != null) {
          pkColumnExpr = arg.columnExpr;
          pkType = valueType;
          pkParamName = param.name;
        }
      }
    }

    AggregateInfo? aggregateInfo;
    if (aggregates.isNotEmpty) {
      if (ownEdges.isNotEmpty || hasManyEdges.isNotEmpty) {
        throw InvalidGenerationSourceError(
          'Aggregate @Queryable classes cannot declare @Relation or @HasMany.',
          element: element,
        );
      }
      final ann = requirePresent(
        queryableChecker.firstAnnotationOfExact(element),
        'the @Queryable annotation',
      );
      final reader = ConstantReader(ann);
      aggregateInfo = AggregateInfo(
        fromMarker: tableMarker,
        joins: _parseAggregateJoins(reader, element),
        dimensions: columnArgs,
        aggregates: aggregates,
        orderByCall: _parseOrderByCall(reader, element),
        orderDesc: reader.read('orderDesc').boolValue,
      );
    }

    return ClassInfo(
      className: requirePresent(element.name, 'the @Queryable class name'),
      tableMarker: tableMarker,
      columnArgs: columnArgs,
      ownEdges: ownEdges,
      hasManyEdges: hasManyEdges,
      aggregateInfo: aggregateInfo,
      pkColumnExpr: pkColumnExpr,
      pkType: pkType,
      pkParamName: pkParamName,
    );
  }

  AggregateField parseAggregateField(
    FieldElement field,
    FormalParameterElement param,
  ) {
    final ann = requirePresent(
      aggChecker.firstAnnotationOfExact(field),
      'the @Agg annotation',
    );
    final selectCall = _selectCallFrom(
      ConstantReader(ann).read('select'),
      field,
      label: '@Agg(select)',
    );
    return AggregateField(
      fieldName: requirePresent(param.name, 'the @Agg field name'),
      selectCall: selectCall,
      zeroFallback: _needsZeroFallback(param.type),
    );
  }

  bool _needsZeroFallback(DartType type) {
    if (type.nullabilitySuffix != NullabilitySuffix.none) return false;
    final name = type.element?.name;
    return name == 'int' || name == 'double' || name == 'num';
  }

  List<AggregateJoin> _parseAggregateJoins(
    ConstantReader ann,
    Element element,
  ) {
    final joins = ann.read('joins');
    if (joins.isNull) return const [];
    return [
      for (final value in joins.listValue) _joinFromRef(value, element),
    ];
  }

  AggregateJoin _joinFromRef(DartObject ref, Element element) {
    final colType = ref.type;
    if (colType is! InterfaceType || colType.typeArguments.length < 3) {
      throw InvalidGenerationSourceError(
        '@Queryable.joins entries must be schema FK refs.',
        element: element,
      );
    }
    final parentMarker = colType.typeArguments[1].element?.name;
    final targetMarker = colType.typeArguments[2].element?.name;
    final sqlName = ref.getField('name')?.toStringValue();
    if (parentMarker == null || targetMarker == null || sqlName == null) {
      throw InvalidGenerationSourceError(
        '@Queryable.joins entries must be schema FK refs.',
        element: element,
      );
    }
    final fkType = colType.typeArguments[0];
    return AggregateJoin(
      parentMarker: parentMarker,
      targetMarker: targetMarker,
      fkColumnExpr: '$parentMarker.${camelCase(sqlName)}',
      nullable: fkType.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  String? _parseOrderByCall(ConstantReader ann, Element element) {
    final orderBy = ann.read('orderBy');
    if (orderBy.isNull) return null;
    return _selectCallFrom(orderBy, element, label: '@Queryable.orderBy');
  }

  String _selectCallFrom(
    ConstantReader reader,
    Element element, {
    required String label,
  }) {
    if (reader.isNull) {
      throw InvalidGenerationSourceError(
        '$label must be a private static tear-off.',
        element: element,
      );
    }
    final fn = reader.objectValue.toFunctionValue();
    if (fn is! MethodElement) {
      throw InvalidGenerationSourceError(
        '$label must be a static method tear-off.',
        element: element,
      );
    }
    if (!fn.isStatic) {
      throw InvalidGenerationSourceError(
        '$label must reference a static method.',
        element: element,
      );
    }
    final fnName = fn.name;
    if (fnName == null || !fnName.startsWith('_')) {
      throw InvalidGenerationSourceError(
        '$label must reference a private static method (name starts with _).',
        element: element,
      );
    }
    final enclosing = fn.enclosingElement;
    if (enclosing is! ClassElement) {
      throw InvalidGenerationSourceError(
        '$label must reference a static method on the view class.',
        element: element,
      );
    }
    return '${enclosing.name}.${fn.name}()';
  }

  /// The table-marker class element (e.g. `Users`) from `@Queryable(table)` —
  /// used to inspect name-matched columns' declared types (PK detection).
  InterfaceElement? _markerElement(ClassElement element) {
    final ann = queryableChecker.firstAnnotationOfExact(element);
    if (ann == null) return null;
    final tableType = ConstantReader(ann).read('table').objectValue.type;
    if (tableType is! InterfaceType) return null;
    final marker = tableType.typeArguments.first.element;
    return marker is InterfaceElement ? marker : null;
  }

  /// If [param]'s mapped column is a `PrimaryKey`, returns its Dart value type
  /// (e.g. `int`); otherwise null. Handles `@Column`-mapped and name-matched.
  String? _primaryKeyType(
    FormalParameterElement param,
    FieldElement? field,
    InterfaceElement? marker,
  ) {
    final colObj = field == null
        ? null
        : columnChecker.firstAnnotationOfExact(field)?.getField('column');
    final DartType? colType;
    if (colObj != null) {
      colType = colObj.type;
    } else {
      final pname = param.name;
      colType = (marker != null && pname != null)
          ? marker.getField(pname)?.type
          : null;
    }
    if (colType is InterfaceType && colType.element.name == 'PrimaryKey') {
      return colType.typeArguments.first.element?.name;
    }
    return null;
  }

  /// Every `@Queryable` class reachable from [root] through `@Relation` edges
  /// (including [root] itself), keyed by class name. Cycles terminate naturally.
  Map<String, ClassInfo> reachableFrom(ClassElement root) {
    final infos = <String, ClassInfo>{};

    void visit(ClassElement element) {
      final name = element.name;
      if (name == null || infos.containsKey(name)) return;
      infos[name] = describe(element);

      final ctor = element.unnamedConstructor;
      if (ctor == null) return;
      for (final param in ctor.formalParameters) {
        final pname = param.name;
        final field = pname == null ? null : element.getField(pname);
        if (field != null && relationChecker.hasAnnotationOfExact(field)) {
          final paramType = param.type;
          if (paramType is InterfaceType) {
            final target = paramType.element;
            if (target is ClassElement &&
                queryableChecker.hasAnnotationOfExact(target)) {
              visit(target);
            }
          }
          continue;
        }
        if (field != null && hasManyChecker.hasAnnotationOfExact(field)) {
          final paramType = param.type;
          if (paramType is InterfaceType &&
              paramType.element.name == 'List' &&
              paramType.typeArguments.isNotEmpty) {
            final childType = paramType.typeArguments.first;
            if (childType is InterfaceType) {
              final target = childType.element;
              if (target is ClassElement &&
                  queryableChecker.hasAnnotationOfExact(target)) {
                visit(target);
              }
            }
          }
        }
      }
    }

    visit(root);
    return infos;
  }

  void _requireOptional(
    FormalParameterElement param,
    FieldElement field,
    String kind,
  ) {
    if (param.isRequiredPositional || param.isRequiredNamed) {
      throw InvalidGenerationSourceError(
        '$kind field "${param.name}" must be optional so its default '
        'can be used.',
        element: field,
      );
    }
  }

  void _requireNamedOptional(
    FormalParameterElement param,
    FieldElement field, {
    String kind = 'Relation',
  }) {
    if (!param.isNamed) {
      throw InvalidGenerationSourceError(
        '$kind field "${param.name}" must be a named constructor '
        'parameter (e.g. `{this.author}`).',
        element: field,
      );
    }
    _requireOptional(param, field, kind);
  }
}
