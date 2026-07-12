/// CLI-facing adapter seam for the Basalt Dart ORM.
///
/// A third entrypoint of `package:basalt`, kept separate from
/// `package:basalt/basalt.dart` so runtime users don't pull in tooling types.
/// Backend packages implement [BasaltAdapter] (and expose it as a top-level
/// `const adapter` in their `lib/adapter.dart`); the basalt CLI consumes it to
/// open connections, reset databases, and resolve `generate-schema` type
/// presets ([SchemaTypeOverrides]/[TypeOverride]).
library;

export 'src/tooling/basalt_adapter.dart';
export 'src/tooling/schema_type_overrides.dart';
export 'src/tooling/schema_type_overrides_parser.dart';
export 'src/tooling/type_override.dart';
