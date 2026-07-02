/// Public description of a registered connection.
final class RegisteredInstance {
  final String id;
  final String name;

  /// Backend kind — `sqlite`, `postgres`, or the runtime type name.
  final String backend;

  const RegisteredInstance({
    required this.id,
    required this.name,
    required this.backend,
  });

  Map<String, Object?> toJson() =>
      {'id': id, 'name': name, 'backend': backend};
}
