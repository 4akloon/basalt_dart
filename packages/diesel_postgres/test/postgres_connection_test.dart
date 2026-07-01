@Timeout(Duration(seconds: 30))
library;

import 'dart:io';

import 'package:diesel/diesel.dart';
import 'package:diesel_postgres/diesel_postgres.dart';
import 'package:test/test.dart';

// int/text columns only: their codecs are identical across SQLite and Postgres.
abstract final class Widgets {
  static const id = PrimaryKey<int, Widgets>('widgets', 'id', SqlType.integer);
  static const name = ValueColumn<String, Widgets>('widgets', 'name', SqlType.text);
  static const qty = ValueColumn<int, Widgets>('widgets', 'qty', SqlType.integer);
  static const table = TableRef<Widgets>('widgets', [id, name, qty]);
}

abstract final class Parts {
  static const id = PrimaryKey<int, Parts>('parts', 'id', SqlType.integer);
  static const widgetId = Ref<int, Parts, Widgets>(
      'parts', 'widget_id', SqlType.integer,
      references: Widgets.id);
  static const label = ValueColumn<String, Parts>('parts', 'label', SqlType.text);
  static const table = TableRef<Parts>('parts', [id, widgetId, label]);
}

void main() {
  late PostgresConnection db;
  var available = true;

  setUpAll(() async {
    final host = Platform.environment['DIESEL_PG_HOST'] ?? 'localhost';
    final port =
        int.tryParse(Platform.environment['DIESEL_PG_PORT'] ?? '') ?? 5433;
    try {
      db = await PostgresConnection.open(
        host: host,
        port: port,
        database: 'diesel_test',
        username: 'postgres',
        password: 'postgres',
        ssl: false,
      );
    } catch (_) {
      available = false;
    }
  });

  tearDownAll(() async {
    if (available) await db.close();
  });

  setUp(() async {
    if (!available) return;
    await db.executeSql('DROP TABLE IF EXISTS parts; DROP TABLE IF EXISTS widgets;');
    await db.executeSql('CREATE TABLE widgets '
        '(id INTEGER PRIMARY KEY, name TEXT NOT NULL, qty INTEGER NOT NULL)');
    await db.executeSql('CREATE TABLE parts '
        '(id INTEGER PRIMARY KEY, widget_id INTEGER NOT NULL REFERENCES widgets(id), '
        'label TEXT NOT NULL)');
  });

  bool skip() {
    if (!available) markTestSkipped('Postgres not reachable (start the container)');
    return !available;
  }

  test(r'insert + typed select ($N placeholders)', () async {
    if (skip()) return;
    await db.execute(insertInto(Widgets.table).values([
      [Widgets.id.set(1), Widgets.name.set('a'), Widgets.qty.set(10)],
      [Widgets.id.set(2), Widgets.name.set('b'), Widgets.qty.set(20)],
    ]));
    final names = await from(Widgets.table)
        .where(Widgets.qty.ge(15))
        .order(Widgets.name.asc())
        .map((r) => r.get(Widgets.name))
        .load(db);
    expect(names, ['b']);
  });

  test('update / delete affected-row counts', () async {
    if (skip()) return;
    await db.execute(insertInto(Widgets.table)
        .value(Widgets.id.set(1))
        .value(Widgets.name.set('a'))
        .value(Widgets.qty.set(1)));
    expect(
        await db.execute(
            update(Widgets.table).value(Widgets.qty.set(5)).where(Widgets.id.eq(1))),
        1);
    expect(
        await db.execute(deleteFrom(Widgets.table).where(Widgets.qty.lt(10))), 1);
  });

  test('RETURNING surfaces columns', () async {
    if (skip()) return;
    final rows = await db.executeReturning(
      insertInto(Widgets.table)
          .value(Widgets.id.set(7))
          .value(Widgets.name.set('x'))
          .value(Widgets.qty.set(3))
          .returning([Widgets.id, Widgets.qty]).map(
              (r) => (r.get(Widgets.id), r.get(Widgets.qty))),
    );
    expect(rows, [(7, 3)]);
  });

  test('join + aggregate', () async {
    if (skip()) return;
    await db.execute(insertInto(Widgets.table).values([
      [Widgets.id.set(1), Widgets.name.set('a'), Widgets.qty.set(10)],
      [Widgets.id.set(2), Widgets.name.set('b'), Widgets.qty.set(20)],
    ]));
    final total = Widgets.qty.sum();
    expect(
        await from(Widgets.table).select([total]).map((r) => r.get(total)).first(db),
        30);

    await db.execute(insertInto(Parts.table)
        .value(Parts.id.set(1))
        .value(Parts.widgetId.set(1))
        .value(Parts.label.set('p1')));
    final joined = await from(Parts.table)
        .innerJoin(Widgets.table, onFk: Parts.widgetId)
        .map((r) => '${r.get(Parts.label)}@${r.get(Widgets.name)}')
        .load(db);
    expect(joined, ['p1@a']);
  });

  test('transaction rolls back on error', () async {
    if (skip()) return;
    await expectLater(
      db.transaction((tx) async {
        await tx.execute(insertInto(Widgets.table)
            .value(Widgets.id.set(99))
            .value(Widgets.name.set('temp'))
            .value(Widgets.qty.set(1)));
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(
      await from(Widgets.table)
          .where(Widgets.id.eq(99))
          .map((r) => r.get(Widgets.id))
          .load(db),
      isEmpty,
    );
  });

  test('introspect reports columns, pk, fk, nullability', () async {
    if (skip()) return;
    final tables = await db.introspect();
    final widgets = tables.firstWhere((t) => t.name == 'widgets');
    expect(widgets.columns.map((c) => c.name), ['id', 'name', 'qty']);
    expect(widgets.columns.firstWhere((c) => c.name == 'id').isPrimaryKey, isTrue);
    expect(widgets.columns.firstWhere((c) => c.name == 'id').type,
        ColumnType.integer);

    final parts = tables.firstWhere((t) => t.name == 'parts');
    final fk = parts.columns.firstWhere((c) => c.name == 'widget_id').foreignKey;
    expect(fk?.table, 'widgets');
    expect(fk?.column, 'id');
  });
}
