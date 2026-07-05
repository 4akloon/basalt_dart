/// Annotations consumed by `basalt_codegen` to derive row mappers and write
/// statements for data classes. They carry no runtime behaviour — only metadata
/// for the generator.
library;

export 'annotations/agg.dart';
export 'annotations/as_changeset.dart';
export 'annotations/column.dart';
export 'annotations/has_many.dart';
export 'annotations/insertable.dart';
export 'annotations/queryable.dart';
export 'annotations/relation.dart';
