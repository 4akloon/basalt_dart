/// build_runner code generator for the Basalt Dart ORM. Wire it via build.yaml;
/// it derives a `RowMapper<T>` for every `@Queryable` class and `toInsert()` /
/// `toUpdate()` extensions for `@Insertable` / `@AsChangeset` classes.
library;

export 'builder.dart';
export 'src/queryable_generator.dart';
export 'src/write_generator.dart';
