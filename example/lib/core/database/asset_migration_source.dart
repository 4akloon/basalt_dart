import 'package:basalt/migration.dart';
import 'package:flutter/services.dart' show AssetBundle, AssetManifest, rootBundle;

/// Discovers migrations bundled as Flutter assets.
///
/// Every asset matching `migrations/<version>_<name>/up.sql` is included,
/// ordered ascending by version. This is the runtime counterpart of
/// [DirectoryMigrationSource] in `basalt_cli`, which reads the same files from
/// disk during development.
final class AssetMigrationSource implements MigrationSource {
  AssetMigrationSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<List<Migration>> discover() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final assets = manifest.listAssets().toSet();
    final migrations = <Migration>[];
    for (final asset in assets) {
      if (!asset.startsWith('migrations/') || !asset.endsWith('/up.sql')) {
        continue;
      }
      final dir = asset.substring('migrations/'.length, asset.length - '/up.sql'.length);
      final sep = dir.indexOf('_');
      if (sep <= 0) continue;
      final version = dir.substring(0, sep);
      final name = dir.substring(sep + 1);
      final up = await _bundle.loadString(asset);
      final downPath = 'migrations/$dir/down.sql';
      final down =
          assets.contains(downPath) ? await _bundle.loadString(downPath) : null;
      migrations.add(
        Migration(version: version, name: name, up: up, down: down),
      );
    }
    migrations.sort((a, b) => a.version.compareTo(b.version));
    return migrations;
  }
}
