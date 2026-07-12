import 'package:analyzer/dart/element/element.dart';
import 'package:basalt/basalt.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'queryable/changeset_emitter.dart';
import 'queryable/edge_analyzer.dart';
import 'queryable/insert_emitter.dart';
import 'queryable/require_present.dart';

/// Emits a `toInsert()` extension for each `@Insertable` data class. Independent
/// of `@Queryable`, so a write-only DTO works on its own.
///
/// {@category getting-started}
class InsertableGenerator extends GeneratorForAnnotation<Insertable> {
  const InsertableGenerator();

  @override
  Iterable<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Insertable can only be applied to classes.',
        element: element,
      );
    }
    const analyzer = EdgeAnalyzer();
    final marker = analyzer.tableMarkerOf(element, insertableChecker);
    if (marker == null) {
      throw InvalidGenerationSourceError(
        '@Insertable(table) must reference a TableRef (e.g. Users.table).',
        element: element,
      );
    }
    return [
      const InsertEmitter().emit(
        className: requirePresent(element.name, 'the @Insertable class name'),
        tableMarker: marker,
        columnArgs: analyzer.writeColumnArgs(element, marker),
      ),
    ];
  }
}

/// Emits a `toUpdate()` extension for each `@AsChangeset` data class.
///
/// {@category getting-started}
class AsChangesetGenerator extends GeneratorForAnnotation<AsChangeset> {
  const AsChangesetGenerator();

  @override
  Iterable<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@AsChangeset can only be applied to classes.',
        element: element,
      );
    }
    const analyzer = EdgeAnalyzer();
    final marker = analyzer.tableMarkerOf(element, asChangesetChecker);
    if (marker == null) {
      throw InvalidGenerationSourceError(
        '@AsChangeset(table) must reference a TableRef (e.g. Users.table).',
        element: element,
      );
    }
    return [
      const ChangesetEmitter().emit(
        className: requirePresent(element.name, 'the @AsChangeset class name'),
        tableMarker: marker,
        columnArgs: analyzer.writeColumnArgs(element, marker),
      ),
    ];
  }
}
