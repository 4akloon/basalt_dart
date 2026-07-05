import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'customer_row.g.dart';

/// The **combined** example: a simple model (no relations) that carries all
/// three derives on one class — `@Queryable` (read + `customerRowMapper` /
/// `customerRowQuery`), `@Insertable` (`toInsert()`) and
/// `@AsChangeset` (`toUpdate()`).
///
/// For rows *with* relations we split read and write into separate classes
/// instead (e.g. `ProductRow` + `ProductWrite`) so the read shape can carry
/// relation fields while the write shape stays a flat column list. Combining is
/// fine — and less boilerplate — when the model is this simple.
///
/// `loyaltyTier` is the raw enum text and `createdAt` is epoch milliseconds; the
/// mapper turns those into a `LoyaltyTier` and a `DateTime`. The `id` is
/// `readOnly` so `toInsert()` lets SQLite autoincrement it.
@Queryable(Customers.table)
@Insertable(Customers.table)
@AsChangeset(Customers.table)
class CustomerRow {
  const CustomerRow({
    required this.id,
    required this.name,
    required this.email,
    required this.loyaltyTier,
    required this.createdAt,
  });

  @Column(Customers.id, readOnly: true)
  final int id;
  final String name;
  final String email;
  final String loyaltyTier;
  final int createdAt;
}
