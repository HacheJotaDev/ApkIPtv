import '../utils/text_utils.dart';

class Series {
  final String id;
  final String name;
  final String categoryId;
  final String logo;
  final String rating;
  final String description;
  final String releaseDate;
  final String genre;
  final String cast;
  final String director;

  Series({
    required this.id,
    required this.name,
    required this.categoryId,
    this.logo = '',
    this.rating = '',
    this.description = '',
    this.releaseDate = '',
    this.genre = '',
    this.cast = '',
    this.director = '',
  });

  factory Series.fromXtream(Map<String, dynamic> json) {
    return Series(
      id: json['series_id']?.toString() ?? '',
      name: TextUtils.cleanText(json['name']?.toString()) ?? 'Sin nombre',
      categoryId: TextUtils.cleanText(json['category_id']?.toString()) ?? '',
      logo: json['cover']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '',
      description: TextUtils.cleanText(json['plot']?.toString()) ?? '',
      releaseDate: json['releaseDate']?.toString() ?? '',
      genre: TextUtils.cleanText(json['genre']?.toString()) ?? '',
      cast: TextUtils.cleanText(json['cast']?.toString()) ?? '',
      director: TextUtils.cleanText(json['director']?.toString()) ?? '',
    );
  }
}

class SeriesEpisode {
  final String id;
  final String name;
  final String episodeNum;
  final String seasonNum;
  final String streamUrl;
  final String containerExtension;

  SeriesEpisode({
    required this.id,
    required this.name,
    this.episodeNum = '',
    this.seasonNum = '',
    this.streamUrl = '',
    this.containerExtension = 'mp4',
  });

  factory SeriesEpisode.fromXtream(Map<String, dynamic> json, String serverUrl, String username, String password) {
    return SeriesEpisode(
      id: json['id']?.toString() ?? '',
      name: TextUtils.cleanText(json['title']?.toString()) ?? 'Episodio',
      episodeNum: json['episode_num']?.toString() ?? '',
      seasonNum: json['season_num']?.toString() ?? '',
      streamUrl: '$serverUrl/series/$username/$password/${json['id']}.${json['container_extension'] ?? 'mp4'}',
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
    );
  }
}

class SeriesInfo {
  final Series series;
  final Map<String, List<SeriesEpisode>> seasons;

  SeriesInfo({required this.series, required this.seasons});
}
