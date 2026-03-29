class ServerProfile {
  ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.hash,
    this.useTls = true,
    this.allowBadCertificate = true,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String hash;
  final bool useTls;
  final bool allowBadCertificate;

  String get baseUrl {
    final scheme = useTls ? 'https' : 'http';
    return '$scheme://$host:$port';
  }

  String get wsBaseUrl {
    final scheme = useTls ? 'wss' : 'ws';
    return '$scheme://$host:$port';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'hash': hash,
        'useTls': useTls,
        'allowBadCertificate': allowBadCertificate,
      };

  factory ServerProfile.fromJson(Map<String, dynamic> j) => ServerProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        host: j['host'] as String,
        port: j['port'] as int,
        hash: j['hash'] as String,
        useTls: j['useTls'] as bool? ?? true,
        allowBadCertificate: j['allowBadCertificate'] as bool? ?? true,
      );
}
