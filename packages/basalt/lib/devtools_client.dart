/// DevTools inspector **client** for the Basalt Dart ORM.
///
/// The consumer-facing half of the `ext.basalt.*` protocol: an
/// [InspectorClient] that calls the extensions a host app registers via
/// `package:basalt/devtools.dart`, plus the shared DTOs and the
/// [InspectorTransport] seam each consumer implements over its own VM service
/// connection (the DevTools extension over `serviceManager`, the MCP server
/// over `package:vm_service`).
///
/// This entrypoint deliberately excludes the host runtime (no registry, no
/// `dart:developer`), so a web client pulls in nothing platform-specific.
library;

export 'src/devtools/client/inspector_client.dart';
export 'src/devtools/client/inspector_transport.dart';
export 'src/devtools/dto/column_dto.dart';
export 'src/devtools/dto/column_filter.dart';
export 'src/devtools/dto/foreign_key_dto.dart';
export 'src/devtools/dto/registered_instance.dart';
export 'src/devtools/dto/schema_dto.dart';
export 'src/devtools/dto/sql_result_dto.dart';
export 'src/devtools/dto/table_dto.dart';
export 'src/devtools/dto/table_page_dto.dart';
export 'src/devtools/protocol/basalt_extension.dart';
