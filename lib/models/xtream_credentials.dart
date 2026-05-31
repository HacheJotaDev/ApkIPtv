class XtreamCredentials {
  final String server;
  final String username;
  final String password;

  XtreamCredentials({
    required this.server,
    required this.username,
    required this.password,
  });

  String get baseUrl {
    String url = server.trim();
    if (!url.startsWith('http')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  String get playerApiUrl => '$baseUrl/player_api.php';
  String get authUrl => '$playerApiUrl?username=$username&password=$password';

  Map<String, String> get authParams => {
    'username': username,
    'password': password,
  };

  Map<String, dynamic> toJson() => {
    'server': server,
    'username': username,
    'password': password,
  };

  factory XtreamCredentials.fromJson(Map<String, dynamic> json) =>
      XtreamCredentials(
        server: json['server'] ?? '',
        username: json['username'] ?? '',
        password: json['password'] ?? '',
      );
}
