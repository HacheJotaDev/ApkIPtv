class Channel {
  final String id;
  final String name;
  final String url;
  final String? logo;
  final String? group;
  final String? epgId;
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.epgId,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'logo': logo,
    'group': group,
    'epgId': epgId,
    'isFavorite': isFavorite,
  };

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    url: json['url'] ?? '',
    logo: json['logo'],
    group: json['group'],
    epgId: json['epgId'],
    isFavorite: json['isFavorite'] ?? false,
  );
}

class VodItem {
  final String id;
  final String name;
  final String url;
  final String? poster;
  final String? group;
  final String? rating;
  final String? year;
  final String? plot;
  final String? duration;
  final String? director;
  final String? cast;
  final String? genre;
  final String? releaseDate;
  final String type; // movie or series
  bool isFavorite;

  VodItem({
    required this.id,
    required this.name,
    required this.url,
    this.poster,
    this.group,
    this.rating,
    this.year,
    this.plot,
    this.duration,
    this.director,
    this.cast,
    this.genre,
    this.releaseDate,
    this.type = 'movie',
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'poster': poster,
    'group': group,
    'rating': rating,
    'year': year,
    'plot': plot,
    'duration': duration,
    'director': director,
    'cast': cast,
    'genre': genre,
    'releaseDate': releaseDate,
    'type': type,
    'isFavorite': isFavorite,
  };

  factory VodItem.fromJson(Map<String, dynamic> json) => VodItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    url: json['url'] ?? '',
    poster: json['poster'],
    group: json['group'],
    rating: json['rating'],
    year: json['year'],
    plot: json['plot'],
    duration: json['duration'],
    director: json['director'],
    cast: json['cast'],
    genre: json['genre'],
    releaseDate: json['releaseDate'],
    type: json['type'] ?? 'movie',
    isFavorite: json['isFavorite'] ?? false,
  );
}

class SeriesSeason {
  final String seasonId;
  final String name;
  final List<Episode> episodes;

  SeriesSeason({
    required this.seasonId,
    required this.name,
    this.episodes = const [],
  });
}

class Episode {
  final String id;
  final String title;
  final String url;
  final int? episodeNum;
  final String? thumbnail;
  final String? plot;
  final double? durationSeconds;

  Episode({
    required this.id,
    required this.title,
    required this.url,
    this.episodeNum,
    this.thumbnail,
    this.plot,
    this.durationSeconds,
  });
}

class EpgProgram {
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;

  EpgProgram({
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
  });
}

class XtreamCredentials {
  final String server;
  final String username;
  final String password;

  XtreamCredentials({
    required this.server,
    required this.username,
    required this.password,
  });

  String get playerApi => '$server/player_api.php?username=$username&password=$password';
  String get liveStreamUrl => '$server/live/$username/$password/';
  String get vodStreamUrl => '$server/movie/$username/$password/';
  String get seriesStreamUrl => '$server/series/$username/$password/';

  Map<String, dynamic> toJson() => {
    'server': server,
    'username': username,
    'password': password,
  };

  factory XtreamCredentials.fromJson(Map<String, dynamic> json) => XtreamCredentials(
    server: json['server'] ?? '',
    username: json['username'] ?? '',
    password: json['password'] ?? '',
  );
}
