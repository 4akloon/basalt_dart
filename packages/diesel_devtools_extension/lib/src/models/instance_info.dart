/// A registered database instance reported by the app.
class InstanceInfo {
  final String id;
  final String name;
  final String backend;
  InstanceInfo(this.id, this.name, this.backend);

  factory InstanceInfo.fromJson(Map json) => InstanceInfo(
        json['id'] as String,
        json['name'] as String,
        json['backend'] as String,
      );
}
