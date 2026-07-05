// Smoke/target harness for the basalt DevTools inspector.
//
// Run with the VM service on so DevTools can attach:
//
//   dart run --observe example/tool/inspector_demo.dart
//
// It seeds an in-memory SQLite database with ~100 users (plus related posts),
// registers it, prints a short summary, then stays alive so you can open the
// "basalt" tab in DevTools and browse / filter / edit it live.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:basalt/devtools.dart';
import 'package:basalt_sqlite/basalt_sqlite.dart';

const _userCount = 100;

const _firstNames = [
  'Alice', 'Bob', 'Cara', 'Dan', 'Eve', 'Frank', 'Grace', 'Heidi', 'Ivan',
  'Judy', 'Karl', 'Liam', 'Mallory', 'Nina', 'Olivia', 'Peggy', 'Quentin',
  'Rupert', 'Sybil', 'Trent', 'Uma', 'Victor', 'Walter', 'Xena', 'Yara', 'Zoe',
];
const _lastNames = [
  'Adams', 'Baker', 'Clark', 'Diaz', 'Evans', 'Ford', 'Green', 'Hughes',
  'Ives', 'Jones', 'Khan', 'Lee', 'Moore', 'Novak', 'Owens', 'Price', 'Quinn',
  'Reed', 'Stone', 'Turner',
];
const _titles = [
  'Hello world', 'Getting started', 'Deep dive', 'Release notes',
  'A retrospective', 'Tips & tricks', 'Postmortem', 'Roadmap', 'Q&A',
  'Changelog',
];

Future<void> main() async {
  final conn = SqliteConnection.memory();
  final posts = await _seed(conn);
  final id = BasaltDevTools.register(conn, name: 'demo');

  const service = InspectorService();
  final pretty = const JsonEncoder.withIndent('  ');
  stdout.writeln('instances: ${pretty.convert([
        for (final i in await service.listInstances()) i.toJson()
      ])}');
  stdout.writeln('seeded: $_userCount users, $posts posts');
  final sample = await service.getTableData(id,
      table: 'users', limit: 3, orderBy: 'id', filters: const []);
  stdout.writeln('first 3 users: ${pretty.convert(sample.rows)}');

  stdout.writeln('\nRegistered instance "$id". Open DevTools on this VM '
      'service and use the basalt tab (try filtering users by name / age / '
      'email IS NULL, or edit a row). Press Enter to exit.');
  await stdin.first;
  await conn.close();
}

/// Seeds the schema and ~100 users with related posts. Returns the post count.
/// Uses a seeded RNG so the data is the same on every run.
Future<int> _seed(SqliteConnection conn) async {
  await conn.executeSql(
    'CREATE TABLE users ('
    'id INTEGER PRIMARY KEY, '
    'name TEXT NOT NULL, '
    'email TEXT, '
    'age INTEGER NOT NULL, '
    'active INTEGER NOT NULL, '
    'created_at INTEGER NOT NULL)',
  );
  await conn.executeSql(
    'CREATE TABLE posts ('
    'id INTEGER PRIMARY KEY, '
    'user_id INTEGER NOT NULL REFERENCES users(id), '
    'title TEXT NOT NULL, '
    'views INTEGER NOT NULL)',
  );

  final rng = Random(42);
  const base = 1719800000000; // 2024-07-01, ms since epoch
  var postCount = 0;

  await conn.transaction((tx) async {
    for (var i = 1; i <= _userCount; i++) {
      final first = _firstNames[rng.nextInt(_firstNames.length)];
      final last = _lastNames[rng.nextInt(_lastNames.length)];
      // ~10% of users have no email (to demo the `IS NULL` filter).
      final email =
          rng.nextInt(10) == 0 ? null : '${first.toLowerCase()}$i@example.com';
      await tx.executeSql(
        'INSERT INTO users (name, email, age, active, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          '$first $last',
          email,
          18 + rng.nextInt(50), // age 18..67
          rng.nextBool() ? 1 : 0, // active
          base + i * 3600000 + rng.nextInt(3600000),
        ],
      );
      for (var p = rng.nextInt(4); p > 0; p--) {
        postCount++;
        await tx.executeSql(
          'INSERT INTO posts (user_id, title, views) VALUES (?, ?, ?)',
          [i, '${_titles[rng.nextInt(_titles.length)]} #$postCount', rng.nextInt(1000)],
        );
      }
    }
  });

  return postCount;
}
