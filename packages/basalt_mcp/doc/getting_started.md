# Getting Started

`basalt_mcp` is an MCP server that lets AI agents inspect live Basalt database
connections in a **running debug app** — schema, table pages, row updates, and
raw SQL. It mirrors the DevTools "basalt" tab, but over MCP tools.

## Prerequisites

1. A Flutter/Dart app with an open Basalt `Connection`.
2. The connection registered for inspection:

```dart
import 'package:basalt/devtools.dart';

BasaltDevTools.register(conn, name: 'main');
```

The example app does this in `lib/main_debug.dart`.

3. Run in **debug** or **profile** mode (VM service required; release builds
   won't expose extensions):

```sh
cd example
flutter run -t lib/main_debug.dart
```

This prints the app's VM service URI (`ws://127.0.0.1:PORT/ws`), which the
`connect` tool needs — see [Finding the VM service URI](#finding-the-vm-service-uri).

## Finding the VM service URI

The `connect` tool needs the app's VM service URI. Two ways to get it:

### Option A — discover it via the Dart MCP server (no copy/paste)

If the [Dart MCP server](https://dart.dev/tools/mcp-server) (`dart` tools) is
configured in your AI tool, let it find the running app through the Dart Tooling
Daemon (DTD) instead of asking you for a URI:

1. **`dart` → `dtd` `listDtdUris`.** Pick the instance whose **Workspace Root**
   is this repo, not `/` or a home dir.
2. **`dart` → `dtd` `connect`** with that DTD URI. The result lists the connected
   apps and prints each app's VM service URI, e.g.
   `uri: ws://127.0.0.1:58915/EMtHsGzkiew=/ws`.
3. Pass that `ws://…/ws` URI to basalt's **`connect`** tool.

If `listDtdUris` shows no repo-rooted instance, or `connect` lists no apps, the
app isn't running in debug/profile mode — (re)launch it (step 3 of
[Prerequisites](#prerequisites)).

### Option B — copy from the console (fallback)

Copy the `ws://…/ws` URI straight from the `flutter run` output and pass it to
`connect`.

> The URI **changes on every hot restart / relaunch**. If basalt tools return
> "Not connected" or target a dead isolate, rediscover (Option A) or recopy
> (Option B) and call `connect` again.

## Install the MCP server

From this monorepo (while developing):

```sh
dart pub get   # at repo root
```

After publish:

```sh
dart pub global activate basalt_mcp
```

## Configure your AI tool

Add to Cursor's MCP config (`.cursor/mcp.json` or project settings):

```json
{
  "mcpServers": {
    "basalt": {
      "command": "dart",
      "args": ["run", "basalt_mcp"],
      "cwd": "/path/to/basalt_dart/packages/basalt_mcp"
    }
  }
}
```

Or, with a global activate:

```json
{
  "mcpServers": {
    "basalt": {
      "command": "basalt_mcp",
      "args": []
    }
  }
}
```

## Workflow

1. `connect` with the VM service URI (see
   [Finding the VM service URI](#finding-the-vm-service-uri)).
2. `list_instances` — pick an instance `id`.
3. `get_schema` — tables and columns.
4. `get_table_data` — browse rows (optional filters JSON).
5. `run_sql` — ad-hoc queries.
6. `update_row` — edit a row by primary key (destructive; use carefully).

## Tools

| Tool | Purpose |
|------|---------|
| `connect` | Attach to a running debug app |
| `disconnect` | Drop the VM service connection |
| `list_instances` | Registered `BasaltDevTools` connections |
| `get_schema` | Introspected schema for an instance |
| `get_table_data` | Paginated table read with optional filters |
| `update_row` | Update one row by primary key |
| `run_sql` | Execute raw SQL |

## Troubleshooting

- **"No isolate found with ext.basalt.listInstances"** — the app never called
  `BasaltDevTools.register`, or you're in release mode.
- **"Not connected"** — call `connect` with a valid `ws://.../ws` URI first.
- **Empty instances** — register at least one connection before calling
  `list_instances`.
