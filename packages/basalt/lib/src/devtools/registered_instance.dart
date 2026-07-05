/// Public description of a registered connection.
final class RegisteredInstance {
  const RegisteredInstance({
    required this.id,
    required this.name,
    required this.backend,
  });
  final String id;
  final String name;

  /// Backend kind — `sqlite`, `postgres`, or the runtime type name.
  final String backend;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'backend': backend};
}
