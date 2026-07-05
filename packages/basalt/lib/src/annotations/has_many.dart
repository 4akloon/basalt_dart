import '../schema/table.dart';

/// Marks a one-to-many relation: [column] is the child's foreign key pointing at
/// this row's primary key (e.g. `@HasMany(Addresses.customerId)` on a customer
/// view). The field must be `List<ChildRow>` where `ChildRow` is `@Queryable`.
///
/// {@category annotations}
class HasMany {
  const HasMany(this.column);
  final Ref column;
}
