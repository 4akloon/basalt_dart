import 'package:basalt_example/domain/entities/loyalty_tier.dart';

/// A shop customer. `tier` and `joinedAt` are rich domain types (the data layer
/// stores them as text and epoch millis respectively).
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.tier,
    required this.joinedAt,
  });

  final int id;
  final String name;
  final String email;
  final LoyaltyTier tier;
  final DateTime joinedAt;
}
