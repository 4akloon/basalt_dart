/// Public description of a registered connection.
final class RegisteredInstance {
  const RegisteredInstance({required this.id, required this.name});

  factory RegisteredInstance.fromJson(Map<String, Object?> json) =>
      RegisteredInstance(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  /// Stable identifier assigned at registration (e.g. `inst-0`).
  final String id;

  /// Human-readable display label.
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};
}
