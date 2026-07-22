# basalt_mcp example

`basalt_mcp` is an MCP server executable, so its "example" is a host
configuration plus a running debug app — not a Dart snippet.

## 1. Instrument the app

Register every connection you want to inspect (debug/profile mode only):

```dart
import 'package:basalt/devtools.dart';

final db = SqliteConnection.open('app.db');
BasaltDevTools.register(db, name: 'main');
```

Run the app and note the VM service URI it prints
(`ws://127.0.0.1:.../ws`).

## 2. Register the server with an MCP host

Cursor / Claude Code / any stdio MCP host:

```json
{
  "mcpServers": {
    "basalt": {
      "command": "dart",
      "args": ["pub", "global", "run", "basalt_mcp"]
    }
  }
}
```

(after `dart pub global activate basalt_mcp`).

## 3. Inspect from the agent

A typical session an agent drives:

1. `connect` — attach to the app's VM service URI.
2. `list_instances` — registered Basalt connections.
3. `get_schema` — tables, columns, and foreign keys.
4. `get_table_data` — page through rows, with filters and ordering.
5. `run_sql` / `update_row` — ad-hoc queries and edits.
6. `disconnect` — detach when done.

See [doc/getting_started.md](https://github.com/4akloon/basalt_dart/tree/main/packages/basalt_mcp/doc/getting_started.md)
for the full tool reference.
