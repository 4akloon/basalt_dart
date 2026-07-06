import 'package:basalt/basalt.dart';
import 'package:basalt_sqlite/basalt_sqlite.dart';
import 'package:test/test.dart';

/// Regression tests for concurrent `transaction()` calls on one connection.
///
/// Nesting is decided by the type of the handle `transaction()` is invoked on
/// (a transaction-scoped connection => SAVEPOINT), and top-level transactions
/// are serialized through a single lock, so parallel calls queue instead of
/// interleaving on the shared connection.
void main() {
  late SqliteConnection db;

  setUp(() async {
    db = SqliteConnection.memory();
    await db.executeSql('CREATE TABLE t (id INTEGER PRIMARY KEY, tag TEXT)');
  });

  tearDown(() async => db.close());

  Future<List<String>> tags() async {
    final rows = await db.queryRaw('SELECT tag FROM t ORDER BY tag');
    return [for (final r in rows) r['tag']! as String];
  }

  test('a failing transaction does not roll back a concurrent committed one',
      () async {
    // A inserts, yields, then fails -> must roll back only its own work.
    final a = db.transaction((tx) async {
      await tx.executeSql("INSERT INTO t (tag) VALUES ('A')");
      await Future<void>.delayed(const Duration(milliseconds: 20));
      throw StateError('A fails');
    });
    // B starts while A is pending, inserts, and commits.
    final b = db.transaction((tx) async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tx.executeSql("INSERT INTO t (tag) VALUES ('B')");
      return 'B ok';
    });

    await expectLater(a, throwsStateError);
    expect(await b, 'B ok');

    // B's row survives; A's is gone. (Previously A's ROLLBACK ate B's insert.)
    expect(await tags(), ['B']);
  });

  test('parallel transactions are serialized, not interleaved', () async {
    final order = <String>[];
    final futures = [
      for (var i = 0; i < 5; i++)
        db.transaction((tx) async {
          order.add('start-$i');
          await tx.executeSql("INSERT INTO t (tag) VALUES ('t$i')");
          // Yield: a non-serialized impl would let the next transaction's
          // BEGIN run here, interleaving statements on the connection.
          await Future<void>.delayed(const Duration(milliseconds: 5));
          order.add('end-$i');
        }),
    ];
    await Future.wait(futures);

    // Each transaction ran to completion before the next started.
    expect(order, [
      for (var i = 0; i < 5; i++) ...['start-$i', 'end-$i'],
    ]);
    expect(await tags(), ['t0', 't1', 't2', 't3', 't4']);
  });

  test('nested savepoint rolls back inner only, siblings keep distinct names',
      () async {
    await db.transaction((tx) async {
      await tx.executeSql("INSERT INTO t (tag) VALUES ('outer')");

      // First nested savepoint: rolled back.
      try {
        await tx.transaction((inner) async {
          await inner.executeSql("INSERT INTO t (tag) VALUES ('inner-bad')");
          throw Exception('inner boom');
        });
      } on Exception {
        // swallow: outer continues
      }

      // Second sibling nested savepoint at the same depth: commits. If sibling
      // savepoints collided on a name this would corrupt the savepoint stack.
      await tx.transaction((inner) async {
        await inner.executeSql("INSERT INTO t (tag) VALUES ('inner-good')");
      });
    });

    expect(await tags(), ['inner-good', 'outer']);
  });

  test('parallel nested siblings: one rolls back without clobbering the other',
      () async {
    // Two nested transactions started concurrently on the same handle. With a
    // shared/depth-based savepoint name they would alias, and A's ROLLBACK TO
    // would target B's savepoint — leaving A's write behind. They must instead
    // serialize and use distinct savepoint names.
    await db.transaction((tx) async {
      final a = () async {
        try {
          await tx.transaction((a) async {
            await a.executeSql("INSERT INTO t (tag) VALUES ('a')");
            await Future<void>.delayed(const Duration(milliseconds: 5));
            throw Exception('a fails');
          });
        } on Exception {
          // swallow: only A rolls back
        }
      }();
      final b = tx.transaction((b) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await b.executeSql("INSERT INTO t (tag) VALUES ('b')");
      });
      await Future.wait([a, b]);
    });

    // A rolled back, B committed.
    expect(await tags(), ['b']);
  });

  test('using a tx handle after its block throws StateError', () async {
    late Connection escaped;
    await db.transaction((tx) async {
      escaped = tx;
      await tx.executeSql("INSERT INTO t (tag) VALUES ('x')");
    });

    expect(
      () => escaped.executeSql("INSERT INTO t (tag) VALUES ('leaked')"),
      throwsStateError,
    );
    // The leaked write never happened.
    expect(await tags(), ['x']);
  });

  test('closing a connection from inside a transaction throws', () async {
    await expectLater(
      db.transaction((tx) => tx.close()),
      throwsStateError,
    );
  });
}
