import 'package:analyzer/dart/element/element.dart';

import 'edge_analyzer.dart';
import 'model_code_generator.dart';
import 'queryable_model.dart';
import 'require_present.dart';

/// Bridges analyzer metadata to [ModelCodeGenerator].
final class QueryableClassCodegen {
  const QueryableClassCodegen({
    this.edgeAnalyzer = const EdgeAnalyzer(),
    this.modelGenerator = const ModelCodeGenerator(),
  });
  final EdgeAnalyzer edgeAnalyzer;
  final ModelCodeGenerator modelGenerator;

  Iterable<String> generate(ClassElement element) {
    // Resolve the relation closure so nested `@HasMany` loaders call the child's
    // generated `loadChild` from its own library (imported by the model file).
    final classInfos = edgeAnalyzer.reachableFrom(element);
    final root = requirePresent(
      classInfos[element.name],
      'the registered ClassInfo for ${element.name}',
    );
    return modelGenerator.generate(
      QueryableModel(
        root: root,
        classInfos: classInfos,
      ),
    );
  }
}

/// Generates code units for a single `@Queryable`-annotated [element].
Iterable<String> generateQueryableClass(ClassElement element) =>
    const QueryableClassCodegen().generate(element);
