# basalt_mcp

![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5-0175C2?logo=dart&logoColor=white)
![Executable](https://img.shields.io/badge/executable-basalt__mcp-blue)
![Part of](https://img.shields.io/badge/part_of-basalt__dart-informational)

**MCP server for [basalt_dart](../../README.md)** — lets AI agents inspect live Basalt database
connections in a running debug app (schema, table data, SQL).

```sh
dart run basalt_mcp
```

Register with Cursor, Claude Code, or any MCP host over stdio. The app must call
`BasaltDevTools.register(conn)` and run in debug/profile mode.

## Guide

See **[doc/getting_started.md](doc/getting_started.md)** for setup, MCP config, and tool reference.

## Tools

`connect` · `disconnect` · `list_instances` · `get_schema` · `get_table_data` · `update_row` ·
`run_sql`
