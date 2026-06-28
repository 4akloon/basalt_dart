import 'package:diesel/diesel.dart';

import 'schema.dart';

part 'user.g.dart';

/// One data class, three derives: read it back with `@Queryable` (`userMapper` /
/// `userQuery`), and write it with `@Insertable` (`toInsert()`) and
/// `@AsChangeset` (`toUpdate()`).
///
/// Note: `active` is `int` because SQLite has no native boolean.
@Queryable(Users.table)
@Insertable(Users.table)
@AsChangeset(Users.table)
class User {
  final int id;
  final String name;
  final int age;
  final int active;

  /// Raw foreign-key value — what `toInsert()`/`toUpdate()` write. Its camelCase
  /// name matches `Users.managerId`, so no `@Column` mapping is needed.
  ///
  /// When ids are database-generated you would instead mark the PK
  /// `@Column(Users.id, readOnly: true)`: read on SELECT, skipped on write.
  final int? managerId;

  /// Read-side relation, filled by joining `users` to itself (see the generated
  /// `userQuery`). Not a column — the write derives skip it.
  @Relation(Users.managerId)
  final User? manager;

  const User(this.id, this.name, this.age, this.active,
      {this.managerId, this.manager});

  @override
  String toString() {
    final boss = manager == null ? '' : ', reports to ${manager!.name}';
    return 'User(#$id $name, age $age$boss)';
  }
}
