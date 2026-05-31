import '../utils/text_utils.dart';

class Movie {
  final String id;
  final String name;
  final String categoryId;
  final String streamUrl;
  final String logo;
  final String rating;
  final String description;
  final String releaseDate;
  final String genre;
  final String director;
  final String cast;
  final String duration;
  final String containerExtension;

  Movie({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.streamUrl,
    this.logo = '',
    this.rating = '',
    this.description = '',
    this.releaseDate = '',
    this.genre = '',
    this.director = '',
    this.cast = '',
    this.duration = '',
    this.containerExtension = 'mp4',
  });

  factory Movie.fromXtream(Map<String, dynamic> json, String serverUrl, String username, String password) {
    return Movie(
      id: json['stream_id']?.toString() ?? '',
      name: TextUtils.cleanText(json['name']?.toString()) ?? 'Sin nombre',
      categoryId: TextUtils.cleanText(json['category_id']?.toString()) ?? '',
      streamUrl: '$serverUrl/movie/$username/$password/${json['stream_id']}.${json['container_extension'] ?? 'mp4'}',
      logo: json['stream_icon']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '',
      description: TextUtils.cleanText(json['plot']?.toString()) ?? '',
      releaseDate: json['releasedate']?.toString() ?? '',
      genre: TextUtils.cleanText(json['genre']?.toString()) ?? '',
      director: TextUtils.cleanText(json['director']?.toString()) ?? '',
      cast: TextUtils.cleanText(json['cast']?.toString()) ?? '',
      duration: json['duration']?.toString() ?? '',
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
    );
  }

  factory Movie.fromM3u(Map<String, dynamic> data) {
    return Movie(
      id: data['id']?.toString() ?? '',
      name: TextUtils.cleanText(data['name']?.toString()) ?? 'Sin nombre',
      categoryId: TextUtils.cleanText(data['group']?.toString()) ?? '',
      streamUrl: data['url']?.toString() ?? '',
      logo: data['logo']?.toString() ?? '',
    );
  }
}
