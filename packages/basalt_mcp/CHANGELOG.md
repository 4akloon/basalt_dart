# Changelog

## 0.1.0

- Requires `basalt >=0.1.0 <0.2.0` — the previous lower bound predated
  `package:basalt/devtools_client.dart` and broke downgrade analysis.
- Added an example (`example/README.md`): app instrumentation, MCP host
  config, and a typical agent session.
- No functional changes.

## 0.0.1

Initial development release of the `basalt_mcp` MCP server.

- Stdio MCP server (`basalt_mcp` executable) using `mcp_dart`.
- Connect to a running debug app via VM service URI.
- Tools proxying `ext.basalt.*` extensions: list instances, schema introspection, table paging,
  row updates, and raw SQL.
