/// DevTools inspector for the Diesel Dart ORM.
///
/// A second entrypoint of `package:diesel`, kept separate from
/// `package:diesel/diesel.dart` so plain ORM users don't pull in the inspector
/// runtime. Register live connections with [DieselDevTools.register] to browse,
/// filter, and edit their tables and run raw SQL from the DevTools "Diesel" tab.
/// Dev-only: the underlying `ext.diesel.*` service extensions require the VM
/// service (debug / `--observe`) and are absent from release builds.
library;

export 'src/devtools/column_filter.dart' show ColumnFilter;
export 'src/devtools/diesel_dev_tools.dart' show DieselDevTools;
export 'src/devtools/dto/column_dto.dart' show ColumnDto;
export 'src/devtools/dto/foreign_key_dto.dart' show ForeignKeyDto;
export 'src/devtools/dto/schema_dto.dart' show SchemaDto;
export 'src/devtools/dto/sql_result_dto.dart' show SqlResultDto;
export 'src/devtools/dto/table_dto.dart' show TableDto;
export 'src/devtools/dto/table_page_dto.dart' show TablePageDto;
export 'src/devtools/inspector_exception.dart' show InspectorException;
export 'src/devtools/inspector_service.dart' show InspectorService;
export 'src/devtools/registered_instance.dart' show RegisteredInstance;
