import 'package:analyzer/dart/element/element.dart';
import 'package:basalt/basalt.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'queryable/queryable.dart';

export 'queryable/queryable.dart';

/// Generates a `${Class}Query` companion for each `@Queryable` class — the
/// companion *is* the canonical query (`extends MappedQuery`/`FoldMappedQuery`)
/// and carries the alias-parameterized `static fromRow` reader plus its
/// `RowMapper`. `@Relation` fields drive nested joins with per-edge depth
/// limits and path-based table aliases.
///
/// {@category getting-started}
class QueryableGenerator extends GeneratorForAnnotation<Queryable> {
  const QueryableGenerator();

  @override
  Iterable<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Queryable can only be applied to classes.',
        element: element,
      );
    }
    return generateQueryableClass(element);
  }
}
