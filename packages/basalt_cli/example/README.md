# basalt_cli example

`basalt_cli` is a command-line tool, so its "example" is a workflow you run from a
directory that contains a `basalt.yaml`. A complete, working setup lives in the
[top-level example app](https://github.com/4akloon/basalt_dart/tree/main/example)
(`example/basalt.yaml` + `example/migrations/`).

## Install

```console
$ dart pub global activate basalt_cli
```

## Typical workflow

From a directory with a `basalt.yaml` (see the example app for a full config):

```console
# Scaffold migration tracking
$ dart run basalt_cli:basalt setup

# Create a new, empty migration
$ dart run basalt_cli:basalt migration generate add_users

# Apply pending migrations
$ dart run basalt_cli:basalt migration run

# Revert / redo the last migration
$ dart run basalt_cli:basalt migration revert
$ dart run basalt_cli:basalt migration redo

# List migration status
$ dart run basalt_cli:basalt migration list

# Generate a typed schema from the live database
$ dart run basalt_cli:basalt generate-schema

# Drop and recreate everything
$ dart run basalt_cli:basalt database reset
```

Point at a non-default config with `--config <path>`.

## `basalt.yaml`

```yaml
backend: basalt_sqlite   # required — the backend package to load
database:
  path: app.db           # option keys are adapter-defined
```

See [the migrations guide](https://github.com/4akloon/basalt_dart/tree/main/packages/basalt_cli/doc/migrations.md)
for the full command reference.
