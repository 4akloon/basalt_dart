// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

User $UserFromRow(
  RowReader r, [
  QuerySource<Users> src = Users.table,
  String prefix = '',
  int budget = 0,
]) =>
    User(
      r.get(src.col(Users.id)),
      r.get(src.col(Users.name)),
      r.get(src.col(Users.age)),
      r.get(src.col(Users.active)),
      managerId: r.get(src.col(Users.managerId)),
      manager: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
          ? null
          : r.get(src.col(Users.managerId)) == null
              ? null
              : $UserFromRow(
                  r,
                  Users.table.aliased('${prefix}manager'),
                  '${prefix}manager_',
                  (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) - 1,
                ),
    );

const userMapper = RowMapper<User>($UserFromRow);

MappedQuery<User> get userQuery {
  final manager = Users.table.aliased('manager');
  return from(Users.table)
      .leftJoin(
        manager,
        on: Users.managerId.eqColumn(manager.col(Users.id)),
      )
      .map((r) => $UserFromRow(r, Users.table, '', 1));
}

/// Fetch the User with the given primary key.
MappedQuery<User> findUser(int id) => userQuery.findBy(Users.id, id);

// **************************************************************************
// InsertableGenerator
// **************************************************************************

extension UserInsert on User {
  InsertStatement<Users> toInsert() => insertInto(Users.table)
      .value(Users.id.set(id))
      .value(Users.name.set(name))
      .value(Users.age.set(age))
      .value(Users.active.set(active))
      .value(Users.managerId.set(managerId));
}

// **************************************************************************
// AsChangesetGenerator
// **************************************************************************

extension UserChangeset on User {
  UpdateStatement<Users> toUpdate() => update(Users.table)
      .value(Users.id.set(id))
      .value(Users.name.set(name))
      .value(Users.age.set(age))
      .value(Users.active.set(active))
      .value(Users.managerId.set(managerId));
}
