/// DevTools inspector **host** for the Basalt Dart ORM.
///
/// A second entrypoint of `package:basalt`, kept separate from
/// `package:basalt/basalt.dart` so plain ORM users don't pull in the inspector
/// runtime. Register live connections with [BasaltDevTools.register] to browse,
/// filter, and edit their tables and run raw SQL from the DevTools "basalt" tab.
/// Dev-only: the underlying `ext.basalt.*` service extensions require the VM
/// service (debug / `--observe`) and are absent from release builds.
///
/// Client tooling (DevTools extension, MCP server) that *calls* these
/// extensions should import `package:basalt/devtools_client.dart` instead.
library;

export 'src/devtools/dto/column_dto.dart';
export 'src/devtools/dto/column_filter.dart';
export 'src/devtools/dto/foreign_key_dto.dart';
export 'src/devtools/dto/registered_instance.dart';
export 'src/devtools/dto/schema_dto.dart';
export 'src/devtools/dto/sql_result_dto.dart';
export 'src/devtools/dto/table_dto.dart';
export 'src/devtools/dto/table_page_dto.dart';
export 'src/devtools/host/basalt_dev_tools.dart';
export 'src/devtools/host/inspector_exception.dart';
export 'src/devtools/host/inspector_service.dart';
export 'src/devtools/protocol/basalt_extension.dart';
