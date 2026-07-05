import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:basalt_cli/basalt_cli.dart';

Future<void> main(List<String> args) async {
  try {
    final code = await const CliRunner().build().run(args);
    exit(code ?? 0);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  } catch (e) {
    if (e is StateError) {
      stderr.writeln('Error: ${e.message}');
      exit(1);
    }
    rethrow;
  }
}
