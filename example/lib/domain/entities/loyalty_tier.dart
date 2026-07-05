/// A customer's loyalty level. Stored in the database as its [name] (`bronze` /
/// `silver` / `gold`) and decoded back by the mapper.
enum LoyaltyTier {
  bronze,
  silver,
  gold;

  /// Human-readable label for the UI.
  String get label => switch (this) {
        LoyaltyTier.bronze => 'Bronze',
        LoyaltyTier.silver => 'Silver',
        LoyaltyTier.gold => 'Gold',
      };
}
