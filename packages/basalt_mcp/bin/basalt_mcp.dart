import 'dart:io';

import 'package:args/args.dart';
import 'package:basalt_mcp/basalt_mcp.dart';

/// Builds the command-line argument parser for the server executable.
ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addOption(
      'log-level',
      abbr: 'l',
      defaultsTo: 'INFO',
      help: 'Log level (FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE).',
    )
    ..addOption(
      'log-file',
      help: 'Path to log file. If not set, logs to stderr.',
    );
}

/// Prints usage information for the server executable to stderr.
void printUsage(ArgParser argParser) {
  stderr
    ..writeln('Basalt MCP Server - live DB inspection for AI agents')
    ..writeln()
    ..writeln('Usage: basalt_mcp [options]')
    ..writeln()
    ..writeln('Options:')
    ..writeln(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final argParser = buildParser();
  try {
    final results = argParser.parse(arguments);

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }

    final logLevel = (results.option('log-level') ?? 'INFO').toUpperCase();
    final logFile = results.option('log-file');

    exitCode = await runMcpServer(logLevel: logLevel, logFile: logFile);
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln();
    printUsage(argParser);
    exitCode = 1;
  } on Exception catch (e) {
    stderr.writeln(e.toString());
    exitCode = 1;
  }
}
