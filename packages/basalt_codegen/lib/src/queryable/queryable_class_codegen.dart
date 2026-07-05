import 'package:analyzer/dart/element/element.dart';

import 'edge_analyzer.dart';
import 'model_code_generator.dart';
import 'queryable_model.dart';

/// Bridges analyzer metadata to [ModelCodeGenerator].
final class QueryableClassCodegen {
  const QueryableClassCodegen({
    this.edgeAnalyzer = const EdgeAnalyzer(),
    this.modelGenerator = const ModelCodeGenerator(),
  });
  final EdgeAnalyzer edgeAnalyzer;
  final ModelCodeGenerator modelGenerator;

  Iterable<String> generate(ClassElement element) {
    // Resolve the whole relation closure (across libraries) so the emitted code
    // never depends on generated symbols from another file.
    final classInfos = edgeAnalyzer.reachableFrom(element);
    final root = classInfos[element.name]!;
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
