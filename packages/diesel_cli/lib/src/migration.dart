import 'dart:io';

/// One on-disk migration: `<dir>/<version>_<name>/{up,down}.sql`.
final class Migration {
  final String version;
  final String name;
  final File upFile;
  final File downFile;

  Migration(this.version, this.name, this.upFile, this.downFile);

  String get up => upFile.readAsStringSync();
  String? get down => downFile.existsSync() ? downFile.readAsStringSync() : null;
}
