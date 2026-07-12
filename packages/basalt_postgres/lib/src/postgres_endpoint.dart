/// A resolved Postgres connection endpoint, parsed from the `database:`
/// options of `basalt.yaml`.
///
/// Two mutually exclusive option shapes are supported:
///
/// ```yaml
/// database:
///   url: postgres://user:secret@localhost:5432/shop?sslmode=disable
/// ```
///
/// or manual keys:
///
/// ```yaml
/// database:
///   host: localhost      # default: localhost
///   port: 5432           # default: 5432
///   database: shop       # required
///   username: postgres   # default: postgres
///   password: secret     # default: empty
///   ssl: false           # default: true
/// ```
///
/// {@category getting-started}
final class PostgresEndpoint {
  const PostgresEndpoint({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    required this.ssl,
  });

  /// Parses [options] — either a lone `url` key or manual keys; mixing the two
  /// (or passing an unknown key) throws [ArgumentError].
  factory PostgresEndpoint.fromOptions(Map<String, Object?> options) {
    for (final key in options.keys) {
      if (!_knownKeys.contains(key)) {
        throw ArgumentError(
          "postgres adapter: unknown database option '$key' "
          '(expected: ${_knownKeys.join(', ')}).',
        );
      }
    }
    if (options['url'] case final Object? url?) {
      if (options.length > 1) {
        throw ArgumentError(
          "postgres adapter: 'url' cannot be combined with other "
          'database options.',
        );
      }
      if (url is! String || url.trim().isEmpty) {
        throw ArgumentError(
          "postgres adapter: 'url' must be a non-empty string.",
        );
      }
      return PostgresEndpoint._parseUrl(url.trim());
    }
    final database = options['database'];
    if (database is! String || database.trim().isEmpty) {
      throw ArgumentError(
        "postgres adapter: `database:` requires a non-empty 'database' name "
        "(or a single 'url').",
      );
    }
    return PostgresEndpoint(
      host: _string(options, 'host') ?? 'localhost',
      port: _port(options['port']),
      database: database.trim(),
      username: _string(options, 'username') ?? 'postgres',
      password: _string(options, 'password') ?? '',
      ssl: _bool(options, 'ssl') ?? true,
    );
  }

  /// Parses a `postgres://user:pass@host:port/db?sslmode=disable` URL.
  factory PostgresEndpoint._parseUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != 'postgres' && uri.scheme != 'postgresql') {
      throw ArgumentError(
        "postgres adapter: 'url' must use the postgres:// or postgresql:// "
        'scheme: $url',
      );
    }
    final database = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    if (database.isEmpty) {
      throw ArgumentError(
        'postgres adapter: the URL must include a database name: $url',
      );
    }
    final credentials = uri.userInfo.split(':');
    return PostgresEndpoint(
      host: uri.host.isEmpty ? 'localhost' : uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: database,
      username: credentials.isNotEmpty && credentials.first.isNotEmpty
          ? Uri.decodeComponent(credentials.first)
          : 'postgres',
      password: credentials.length > 1
          ? Uri.decodeComponent(credentials[1])
          : '',
      // Default to SSL; opt out for local/dev with `?sslmode=disable`.
      ssl: uri.queryParameters['sslmode'] != 'disable',
    );
  }

  static const _knownKeys = {
    'url',
    'host',
    'port',
    'database',
    'username',
    'password',
    'ssl',
  };

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  /// Whether to require SSL (`sslmode=disable` / `ssl: false` opts out).
  final bool ssl;

  static String? _string(Map<String, Object?> options, String key) {
    final value = options[key];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw ArgumentError(
        "postgres adapter: '$key' must be a non-empty string.",
      );
    }
    return value.trim();
  }

  static int _port(Object? value) => switch (value) {
        null => 5432,
        final int port => port,
        _ => throw ArgumentError("postgres adapter: 'port' must be an int."),
      };

  static bool? _bool(Map<String, Object?> options, String key) {
    final value = options[key];
    if (value == null) return null;
    if (value is! bool) {
      throw ArgumentError("postgres adapter: '$key' must be a bool.");
    }
    return value;
  }
}
