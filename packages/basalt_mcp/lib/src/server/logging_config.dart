import 'dart:io';

import 'package:logging/logging.dart' as logging;

/// Configures the root logger at [logLevelName], writing to [logFile] if given
/// (created if missing) or to stderr otherwise.
void configureLogging(String logLevelName, String? logFile) {
  logging.Logger.root.level = _level(logLevelName);
  final sink = _sink(logFile);
  logging.Logger.root.onRecord.listen((record) {
    sink('[${record.level.name}][${record.loggerName}] ${record.message}');
  });
}

logging.Level _level(String name) => logging.Level.LEVELS.firstWhere(
      (level) => level.name == name,
      orElse: () => logging.Level.INFO,
    );

void Function(String) _sink(String? logFile) {
  if (logFile == null) return stderr.writeln;
  final file = File(logFile)..createSync(recursive: true);
  return (line) => file.writeAsStringSync('$line\n', mode: FileMode.append);
}
