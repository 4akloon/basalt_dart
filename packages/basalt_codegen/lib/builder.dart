import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/queryable_generator.dart';
import 'src/write_generator.dart';

/// build_runner entry point (wired in `build.yaml`). Emits a shared part so the
/// generated readers/mappers and `toInsert()`/`toUpdate()` extensions live in
/// `<file>.g.dart` alongside the user's classes. A class can carry several of
/// `@Queryable`/`@Insertable`/`@AsChangeset`; each generator contributes its
/// own (non-overlapping) units to the same part.
Builder queryableBuilder(BuilderOptions options) => SharedPartBuilder(
      [
        const QueryableGenerator(),
        const InsertableGenerator(),
        const AsChangesetGenerator(),
      ],
      'basalt',
    );
