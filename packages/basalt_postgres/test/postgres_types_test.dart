@Timeout(Duration(seconds: 30))
library;

import 'dart:io';

import 'package:basalt/basalt.dart';
import 'package:basalt_postgres/basalt_postgres.dart';
import 'package:test/test.dart';

// Native Postgres uuid / numeric / array columns via the native-type codecs.
final class Records extends TableRef<Records> {
  const Records._() : super('records');

  static const table = Records._();

  static const id = PrimaryKey<int, Records>(table, 'id', IntSqlType());
  static const ref =
      ValueColumn<String, Records>(table, 'ref', PostgresUuidSqlType());
  static const amount = ValueColumn<String, Records>(
    table,
    'amount',
    PostgresNumericSqlType(),
  );
  static const tags = ValueColumn<List<String>, Records>(
    table,
    'tags',
    PostgresArraySqlType<String>(),
  );
  static const scores = ValueColumn<List<int>, Records>(
    table,
    'scores',
    PostgresArraySqlType<int>(),
  );
  static const notes = ValueColumn<List<String>?, Records>(
    table,
    'notes',
    NullableSqlType(PostgresArraySqlType<String>()),
  );

  @override
  List<TableColumn<Object?, Object?>> get columns =>
      const [id, ref, amount, tags, scores, notes];
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
    await db.executeSql('DROP TABLE IF EXISTS records');
    await db.executeSql('CREATE TABLE records ('
        'id INTEGER PRIMARY KEY, '
        'ref UUID NOT NULL, '
        'amount NUMERIC NOT NULL, '
        'tags TEXT[] NOT NULL, '
        'scores INTEGER[] NOT NULL, '
        'notes TEXT[])');
  });

  bool skip() {
    if (!available) {
      markTestSkipped('Postgres not reachable (start the container)');
    }
    return !available;
  }

  const uuid = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  test('uuid / numeric / array columns round-trip', () async {
    if (skip()) return;
    await db.execute(
      insertInto(Records.table)
          .value(Records.id.set(1))
          .value(Records.ref.set(uuid))
          .value(Records.amount.set('1234.5678'))
          .value(Records.tags.set(['x', 'y', 'z']))
          .value(Records.scores.set([1, 2, 3]))
          .value(Records.notes.set(['hello'])),
    );

    final row = await from(Records.table)
        .map(
          (r) => (
            ref: r.get(Records.ref),
            amount: r.get(Records.amount),
            tags: r.get(Records.tags),
            scores: r.get(Records.scores),
            notes: r.get(Records.notes),
          ),
        )
        .first(db);

    expect(row.ref, uuid);
    expect(row.amount, '1234.5678'); // exact, not lossy double
    expect(row.tags, ['x', 'y', 'z']);
    expect(row.scores, [1, 2, 3]);
    expect(row.notes, ['hello']);
  });

  test('nullable array column reads back null', () async {
    if (skip()) return;
    await db.execute(
      insertInto(Records.table)
          .value(Records.id.set(2))
          .value(Records.ref.set(uuid))
          .value(Records.amount.set('0'))
          .value(Records.tags.set(<String>[]))
          .value(Records.scores.set(<int>[])),
    );

    final row = await from(Records.table)
        .map(
          (r) => (tags: r.get(Records.tags), notes: r.get(Records.notes)),
        )
        .first(db);
    expect(row.tags, isEmpty);
    expect(row.notes, isNull);
  });

  test('introspection keys arrays by udt_name and surfaces uuid/numeric',
      () async {
    if (skip()) return;
    final tables = await db.introspect();
    final records = tables.firstWhere((t) => t.name == 'records');
    final byName = {for (final c in records.columns) c.name: c};

    expect(byName['ref']!.rawType, 'uuid');
    expect(byName['amount']!.rawType, 'numeric');
    expect(byName['tags']!.rawType, '_text');
    expect(byName['scores']!.rawType, '_int4');
    expect(byName['notes']!.isNullable, isTrue);
  });
}
