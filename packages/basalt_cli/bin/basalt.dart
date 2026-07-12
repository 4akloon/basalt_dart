import 'dart:io';

import 'package:basalt_cli/basalt_cli.dart';

Future<void> main(List<String> args) async {
  try {
    exit(await const Bootstrapper().run(args));
  } catch (e) {
    if (e is StateError) {
      stderr.writeln('Error: ${e.message}');
      exit(1);
    }
    rethrow;
  }
}
