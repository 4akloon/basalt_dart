# Changelog

## 0.0.1

Initial development release of the `basalt_mcp` MCP server.

- Stdio MCP server (`basalt_mcp` executable) using `mcp_dart`.
- Connect to a running debug app via VM service URI.
- Tools proxying `ext.basalt.*` extensions: list instances, schema introspection, table paging,
  row updates, and raw SQL.
