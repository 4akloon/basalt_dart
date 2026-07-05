/// A customer delivery address.
class Address {
  const Address({
    required this.id,
    required this.customerId,
    required this.label,
    required this.city,
    required this.street,
  });

  final int id;
  final int customerId;
  final String label;
  final String city;
  final String street;

  String get formatted => '$street, $city';
}
