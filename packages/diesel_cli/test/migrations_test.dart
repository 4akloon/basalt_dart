import 'dart:io';

import 'package:diesel/diesel.dart';
import 'package:diesel_cli/diesel_cli.dart';
import 'package:diesel_sqlite/diesel_sqlite.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Typed view of the table a test migration creates — lets us assert the up/down
/// SQL really ran by querying through the ORM.
abstract final class Widgets {
  static const id = PrimaryKey<int, Widgets>('widgets', 'id', SqlType.integer);
  static const name = ValueColumn<String, Widgets>('widgets', 'name', SqlType.text);
  static const table = TableRef<Widgets>('widgets', [id, name]);
}

void writeMigration(String dir, String version, String name,
    {required String up, required String down}) {
  final mdir = Directory(p.join(dir, '${version}_$name'))..createSync(recursive: true);
  File(p.join(mdir.path, 'up.sql')).writeAsStringSync(up);
  File(p.join(mdir.path, 'down.sql')).writeAsStringSync(down);
}

void main() {
  late Directory tmp;
  late SqliteConnection db;
  late MigrationRunner runner;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('diesel_cli_test');
    db = SqliteConnection.memory();
    runner = MigrationRunner(db, tmp.path);
  });

  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  test('runPending applies pending migrations and records versions', () async {
    writeMigration(tmp.path, '20200101000000', 'create_widgets',
        up: 'CREATE TABLE widgets (id INTEGER PRIMARY KEY, name TEXT NOT NULL);',
        down: 'DROP TABLE widgets;');

    final ran = await runner.runPending();
    expect(ran, ['20200101000000']);
    expect(await runner.appliedVersions(), ['20200101000000']);

    // The up.sql really ran: we can write and read through the new table.
    await db.execute(insertInto(Widgets.table).value(Widgets.id.set(1)).value(Widgets.name.set('a')));
    expect(await db.fetch(from(Widgets.table).map((r) => r.get(Widgets.name))), ['a']);

    // Re-running is a no-op.
    expect(await runner.runPending(), isEmpty);
  });

  test('applies multiple migrations in version order', () async {
    writeMigration(tmp.path, '20200101000000', 'create_widgets',
        up: 'CREATE TABLE widgets (id INTEGER PRIMARY KEY, name TEXT NOT NULL);',
        down: 'DROP TABLE widgets;');
    writeMigration(tmp.path, '20200102000000', 'seed_widgets',
        up: "INSERT INTO widgets (id, name) VALUES (1, 'seed');",
        down: 'DELETE FROM widgets;');

    final ran = await runner.runPending();
    expect(ran, ['20200101000000', '20200102000000']);
    expect(await db.fetch(from(Widgets.table).map((r) => r.get(Widgets.name))), ['seed']);
  });

  test('revertLast runs down.sql and forgets the version', () async {
    writeMigration(tmp.path, '20200101000000', 'create_widgets',
        up: 'CREATE TABLE widgets (id INTEGER PRIMARY KEY, name TEXT NOT NULL);',
        down: 'DROP TABLE widgets;');
    await runner.runPending();

    final reverted = await runner.revertLast();
    expect(reverted, '20200101000000');
    expect(await runner.appliedVersions(), isEmpty);

    // down.sql dropped the table → querying it now fails.
    await expectLater(
      db.fetch(from(Widgets.table).map((r) => r.get(Widgets.id))),
      throwsA(anything),
    );
    expect(await runner.revertLast(), isNull); // nothing left
  });

  test('status reports applied and pending', () async {
    writeMigration(tmp.path, '20200101000000', 'a',
        up: 'CREATE TABLE widgets (id INTEGER PRIMARY KEY, name TEXT NOT NULL);',
        down: 'DROP TABLE widgets;');
    writeMigration(tmp.path, '20200102000000', 'b',
        up: "INSERT INTO widgets (id, name) VALUES (1, 'x');", down: 'DELETE FROM widgets;');

    await runner.runPending();
    await runner.revertLast(); // undo b only

    final status = await runner.status();
    expect(status.applied, ['20200101000000']);
    expect(status.pending.map((m) => m.version), ['20200102000000']);
  });

  test('generateMigration scaffolds up.sql and down.sql', () {
    final dir = const MigrationScaffolder().scaffold('add_things', tmp.path);
    expect(Directory(dir).existsSync(), isTrue);
    expect(p.basename(dir), endsWith('_add_things'));
    expect(File(p.join(dir, 'up.sql')).existsSync(), isTrue);
    expect(File(p.join(dir, 'down.sql')).existsSync(), isTrue);
  });
}
