import 'dart:io';

/// One on-disk migration: `<dir>/<version>_<name>/{up,down}.sql`.
///
/// {@category migrations}
final class Migration {
  Migration(this.version, this.name, this.upFile, this.downFile);
  final String version;
  final String name;
  final File upFile;
  final File downFile;

  String get up => upFile.readAsStringSync();
  String? get down =>
      downFile.existsSync() ? downFile.readAsStringSync() : null;
}
