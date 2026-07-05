/// DevTools inspector for the Basalt Dart ORM.
///
/// A second entrypoint of `package:basalt`, kept separate from
/// `package:basalt/basalt.dart` so plain ORM users don't pull in the inspector
/// runtime. Register live connections with [BasaltDevTools.register] to browse,
/// filter, and edit their tables and run raw SQL from the DevTools "basalt" tab.
/// Dev-only: the underlying `ext.basalt.*` service extensions require the VM
/// service (debug / `--observe`) and are absent from release builds.
library;

export 'src/devtools/basalt_dev_tools.dart';
export 'src/devtools/column_filter.dart';
export 'src/devtools/dto/column_dto.dart';
export 'src/devtools/dto/foreign_key_dto.dart';
export 'src/devtools/dto/schema_dto.dart';
export 'src/devtools/dto/sql_result_dto.dart';
export 'src/devtools/dto/table_dto.dart';
export 'src/devtools/dto/table_page_dto.dart';
export 'src/devtools/inspector_exception.dart';
export 'src/devtools/inspector_service.dart';
export 'src/devtools/registered_instance.dart';
