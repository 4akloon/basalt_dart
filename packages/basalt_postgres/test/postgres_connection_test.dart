@Timeout(Duration(seconds: 30))
library;

import 'dart:io';

import 'package:basalt/basalt.dart';
import 'package:basalt_postgres/basalt_postgres.dart';
import 'package:test/test.dart';

// int/text columns only: their codecs are identical across SQLite and Postgres.
abstract final class Widgets {
  static const id = PrimaryKey<int, Widgets>('widgets', 'id', IntSqlType());
  static const name =
      ValueColumn<String, Widgets>('widgets', 'name', StringSqlType());
  static const qty = ValueColumn<int, Widgets>('widgets', 'qty', IntSqlType());
  static const table = TableRef<Widgets>('widgets', [id, name, qty]);
}

abstract final class Parts {
  static const id = PrimaryKey<int, Parts>('parts', 'id', IntSqlType());
  static const widgetId = Ref<int, Parts, Widgets>(
    'parts',
    'widget_id',
    IntSqlType(),
    references: Widgets.id,
  );
  static const label =
      ValueColumn<String, Parts>('parts', 'label', StringSqlType());
  static const table = TableRef<Parts>('parts', [id, widgetId, label]);
}

// Native Postgres bool + timestamp — exercises the cross-backend codecs.
abstract final class Flags {
  static const id = PrimaryKey<int, Flags>('flags', 'id', IntSqlType());
  static const active =
      ValueColumn<bool, Flags>('flags', 'active', BooleanSqlType());
  static const createdAt =
      ValueColumn<DateTime, Flags>('flags', 'created_at', DateTimeSqlType());
  static const table = TableRef<Flags>('flags', [id, active, createdAt]);
}

void main() {
  late PostgresConnection db;
  var available = true;

  setUpAll(() async {
    final host = Platform.environment['BASALT_PG_HOST'] ?? 'localhost';
    final port =
        int.tryParse(Platform.environment['BASALT_PG_PORT'] ?? '') ?? 5433;
    try {
      db = await PostgresConnection.open(
        host: host,
        port: port,
        database: 'basalt_test',
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
    await db.executeSql('DROP TABLE IF EXISTS parts; '
        'DROP TABLE IF EXISTS widgets; DROP TABLE IF EXISTS flags;');
    await db.executeSql('CREATE TABLE widgets '
        '(id INTEGER PRIMARY KEY, name TEXT NOT NULL, qty INTEGER NOT NULL)');
    await db.executeSql('CREATE TABLE parts '
        '(id INTEGER PRIMARY KEY, widget_id INTEGER NOT NULL REFERENCES widgets(id), '
        'label TEXT NOT NULL)');
    await db.executeSql('CREATE TABLE flags '
        '(id INTEGER PRIMARY KEY, active BOOLEAN NOT NULL, created_at TIMESTAMPTZ NOT NULL)');
  });

  bool skip() {
    if (!available) {
      markTestSkipped('Postgres not reachable (start the container)');
    }
    return !available;
  }

  test(r'insert + typed select ($N placeholders)', () async {
    if (skip()) return;
    await db.execute(
      insertInto(Widgets.table).values([
        [Widgets.id.set(1), Widgets.name.set('a'), Widgets.qty.set(10)],
        [Widgets.id.set(2), Widgets.name.set('b'), Widgets.qty.set(20)],
      ]),
    );
    final names = await from(Widgets.table)
        .where(Widgets.qty.ge(15))
        .order(Widgets.name.asc())
        .map((r) => r.get(Widgets.name))
        .load(db);
    expect(names, ['b']);
  });

  test('update / delete affected-row counts', () async {
    if (skip()) return;
    await db.execute(
      insertInto(Widgets.table)
          .value(Widgets.id.set(1))
          .value(Widgets.name.set('a'))
          .value(Widgets.qty.set(1)),
    );
    expect(
      await db.execute(
        update(Widgets.table).value(Widgets.qty.set(5)).where(Widgets.id.eq(1)),
      ),
      1,
    );
    expect(
      await db.execute(deleteFrom(Widgets.table).where(Widgets.qty.lt(10))),
      1,
    );
  });

  test('updateAll updates many rows with per-row values in one statement',
      () async {
    if (skip()) return;
    await db.execute(
      insertInto(Widgets.table).values([
        [Widgets.id.set(1), Widgets.name.set('a'), Widgets.qty.set(1)],
        [Widgets.id.set(2), Widgets.name.set('b'), Widgets.qty.set(2)],
        [Widgets.id.set(3), Widgets.name.set('c'), Widgets.qty.set(3)],
      ]),
    );

    final affected = await db.execute(
      updateAll(Widgets.table).keyedBy(Widgets.id).values([
        [Widgets.id.set(1), Widgets.name.set('A'), Widgets.qty.set(10)],
        [Widgets.id.set(3), Widgets.name.set('C'), Widgets.qty.set(30)],
        // No widget 99: matches nothing, updates nothing.
        [Widgets.id.set(99), Widgets.name.set('X'), Widgets.qty.set(0)],
      ]),
    );
    expect(affected, 2);

    final rows = await from(Widgets.table)
        .order(Widgets.id.asc())
        .map((r) => (r.get(Widgets.name), r.get(Widgets.qty)))
        .load(db);
    expect(rows, [('A', 10), ('b', 2), ('C', 30)]);
  });

  test('updateAll composes with RETURNING', () async {
    if (skip()) return;
    await db.execute(
      insertInto(Widgets.table).values([
        [Widgets.id.set(1), Widgets.name.set('a'), Widgets.qty.set(1)],
        [Widgets.id.set(2), Widgets.name.set('b'), Widgets.qty.set(2)],
      ]),
    );
    final returned = await db.executeReturning(
      updateAll(Widgets.table).keyedBy(Widgets.id).values([
        [Widgets.id.set(1), Widgets.qty.set(10)],
        [Widgets.id.set(2), Widgets.qty.set(20)],
      ]).returning([Widgets.id, Widgets.qty]).map(
        (r) => (r.get(Widgets.id), r.get(Widgets.qty)),
      ),
    );
    expect(returned.toSet(), {(1, 10), (2, 20)});
  });

  test('updateAll casts native bool + timestamp VALUES columns', () async {
    if (skip()) return;
    final before = DateTime.utc(2024, 1, 1);
    final after = DateTime.utc(2025, 6, 30, 8, 15);
    await db.execute(
      insertInto(Flags.table).values([
        [Flags.id.set(1), Flags.active.set(false), Flags.createdAt.set(before)],
        [Flags.id.set(2), Flags.active.set(true), Flags.createdAt.set(before)],
      ]),
    );

    final affected = await db.execute(
      updateAll(Flags.table).keyedBy(Flags.id).values([
        [Flags.id.set(1), Flags.active.set(true), Flags.createdAt.set(after)],
        [Flags.id.set(2), Flags.active.set(false), Flags.createdAt.set(after)],
      ]),
    );
    expect(affected, 2);

    final rows = await from(Flags.table)
        .order(Flags.id.asc())
        .map((r) => (r.get(Flags.active), r.get(Flags.createdAt).toUtc()))
        .load(db);
    expect(rows, [(true, after), (false, after)]);
  });

  test('RETURNING surfaces columns', () async {
    if (skip()) return;
    final rows = await db.executeReturning(
      insertInto(Widgets.table)
          .value(Widgets.id.set(7))
          .value(Widgets.name.set('x'))
          .value(Widgets.qty.set(3))
          .returning([Widgets.id, Widgets.qty]).map(
        (r) => (r.get(Widgets.id), r.get(Widgets.qty)),
      ),
    );
    expect(rows, [(7, 3)]);
  });

  test('join + aggregate', () async {
    if (skip()) return;
    await db.execute(
      insertInto(Widgets.table).values([
        [Widgets.id.set(1), Widgets.name.set('a'), Widgets.qty.set(10)],
        [Widgets.id.set(2), Widgets.name.set('b'), Widgets.qty.set(20)],
      ]),
    );
    final total = Widgets.qty.sum();
    expect(
      await from(Widgets.table)
          .select([total])
          .map((r) => r.get(total))
          .first(db),
      30,
    );

    await db.execute(
      insertInto(Parts.table)
          .value(Parts.id.set(1))
          .value(Parts.widgetId.set(1))
          .value(Parts.label.set('p1')),
    );
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
        await tx.execute(
          insertInto(Widgets.table)
              .value(Widgets.id.set(99))
              .value(Widgets.name.set('temp'))
              .value(Widgets.qty.set(1)),
        );
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

  test('parallel transactions are serialized; failure does not clobber commit',
      () async {
    if (skip()) return;
    // A inserts, yields, then fails -> rolls back only its own row.
    final a = db.transaction((tx) async {
      await tx.execute(
        insertInto(Widgets.table)
            .value(Widgets.id.set(1))
            .value(Widgets.name.set('a'))
            .value(Widgets.qty.set(1)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      throw StateError('boom');
    });
    // B starts while A is pending, inserts, commits.
    final b = db.transaction((tx) async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tx.execute(
        insertInto(Widgets.table)
            .value(Widgets.id.set(2))
            .value(Widgets.name.set('b'))
            .value(Widgets.qty.set(2)),
      );
      return 'ok';
    });

    await expectLater(a, throwsStateError);
    expect(await b, 'ok');

    final ids = await from(Widgets.table)
        .order(Widgets.id.asc())
        .map((r) => r.get(Widgets.id))
        .load(db);
    expect(ids, [2]);
  });

  test('nested savepoint rolls back inner only', () async {
    if (skip()) return;
    await db.transaction((tx) async {
      await tx.execute(
        insertInto(Widgets.table)
            .value(Widgets.id.set(1))
            .value(Widgets.name.set('outer'))
            .value(Widgets.qty.set(1)),
      );
      try {
        await tx.transaction((inner) async {
          await inner.execute(
            insertInto(Widgets.table)
                .value(Widgets.id.set(2))
                .value(Widgets.name.set('inner'))
                .value(Widgets.qty.set(2)),
          );
          throw Exception('inner boom');
        });
      } on Exception {
        // swallow: outer continues
      }
    });

    final ids = await from(Widgets.table)
        .order(Widgets.id.asc())
        .map((r) => r.get(Widgets.id))
        .load(db);
    expect(ids, [1]);
  });

  test('parallel nested siblings: one rolls back without clobbering the other',
      () async {
    if (skip()) return;
    await db.transaction((tx) async {
      final a = () async {
        try {
          await tx.transaction((a) async {
            await a.execute(
              insertInto(Widgets.table)
                  .value(Widgets.id.set(1))
                  .value(Widgets.name.set('a'))
                  .value(Widgets.qty.set(1)),
            );
            await Future<void>.delayed(const Duration(milliseconds: 5));
            throw Exception('a fails');
          });
        } on Exception {
          // swallow: only A rolls back
        }
      }();
      final b = tx.transaction((b) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await b.execute(
          insertInto(Widgets.table)
              .value(Widgets.id.set(2))
              .value(Widgets.name.set('b'))
              .value(Widgets.qty.set(2)),
        );
      });
      await Future.wait([a, b]);
    });

    final ids = await from(Widgets.table)
        .order(Widgets.id.asc())
        .map((r) => r.get(Widgets.id))
        .load(db);
    expect(ids, [2]);
  });

  test('using a tx handle after its block throws', () async {
    if (skip()) return;
    late Connection escaped;
    await db.transaction((tx) async {
      escaped = tx;
    });
    await expectLater(
      escaped.execute(
        insertInto(Widgets.table)
            .value(Widgets.id.set(1))
            .value(Widgets.name.set('leaked'))
            .value(Widgets.qty.set(1)),
      ),
      throwsStateError,
    );
  });

  test('native bool + timestamp columns round-trip', () async {
    if (skip()) return;
    final ts = DateTime.utc(2024, 1, 15, 12, 30, 45);
    await db.execute(
      insertInto(Flags.table).values([
        [Flags.id.set(1), Flags.active.set(true), Flags.createdAt.set(ts)],
        [Flags.id.set(2), Flags.active.set(false), Flags.createdAt.set(ts)],
      ]),
    );

    // Native boolean predicate + decode.
    final activeIds = await from(Flags.table)
        .where(Flags.active.eq(true))
        .map((r) => r.get(Flags.id))
        .load(db);
    expect(activeIds, [1]);

    final (active, at) = await from(Flags.table)
        .findBy(Flags.id, 1)
        .map((r) => (r.get(Flags.active), r.get(Flags.createdAt)))
        .first(db);
    expect(active, isTrue);
    expect(at.toUtc(), ts);
  });

  test('introspect reports columns, pk, fk, nullability', () async {
    if (skip()) return;
    final tables = await db.introspect();
    final widgets = tables.firstWhere((t) => t.name == 'widgets');
    expect(widgets.columns.map((c) => c.name), ['id', 'name', 'qty']);
    expect(
        widgets.columns.firstWhere((c) => c.name == 'id').isPrimaryKey, isTrue);
    expect(
      widgets.columns.firstWhere((c) => c.name == 'id').type,
      ColumnType.integer,
    );

    final parts = tables.firstWhere((t) => t.name == 'parts');
    final fk =
        parts.columns.firstWhere((c) => c.name == 'widget_id').foreignKey;
    expect(fk?.table, 'widgets');
    expect(fk?.column, 'id');
  });
}
