import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:basalt/tooling.dart';

import 'cli_runner.dart';

/// Runs the basalt CLI against the given backend [adapter] and returns the
/// process exit code.
///
/// This is what the generated `.dart_tool/basalt/entrypoint.dart` calls with
/// the adapter of the package selected by `backend:` in `basalt.yaml`.
///
/// {@category getting-started}
Future<int> runBasalt(
  List<String> args, {
  required BasaltAdapter adapter,
}) async {
  try {
    final code = await CliRunner(adapter).build().run(args);
    return code ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    return 64;
  } catch (e) {
    // Config problems (StateError) and adapter option problems (ArgumentError)
    // are user-facing; anything else is a bug and should crash loudly.
    switch (e) {
      case StateError(:final message):
        stderr.writeln('Error: $message');
        return 1;
      case ArgumentError(:final message):
        stderr.writeln('Error: $message');
        return 1;
      default:
        rethrow;
    }
  }
}
