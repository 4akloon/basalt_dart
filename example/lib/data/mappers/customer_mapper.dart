import 'package:basalt_example/data/models/customer_row.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/loyalty_tier.dart';

/// Converts a [CustomerRow] into a domain [Customer], decoding the raw tier text
/// into a [LoyaltyTier] and epoch millis into a [DateTime].
extension CustomerRowMapper on CustomerRow {
  Customer toDomain() => Customer(
        id: id,
        name: name,
        email: email,
        tier: LoyaltyTier.values.byName(loyaltyTier),
        joinedAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      );
}
