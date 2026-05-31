import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/xtream_credentials.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';

class XtreamService {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>?> authenticate(XtreamCredentials creds) async {
    try {
      final url = Uri.parse(creds.authUrl);
      final response = await _client.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['user_info'] != null && data['user_info']['auth'] == 1) {
          return data;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Category>> getLiveCategories(XtreamCredentials creds) async {
    try {
      final url = Uri.parse('${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_live_categories');
      final response = await _client.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Category.fromJson(e, type: 'live')).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Channel>> getLiveStreams(XtreamCredentials creds, {String? categoryId}) async {
    try {
      var urlStr = '${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_live_streams';
      final url = Uri.parse(urlStr);
      final response = await _client.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        var channels = data.map((e) => Channel.fromXtream(e, creds.baseUrl, creds.username, creds.password)).toList();
        if (categoryId != null && categoryId.isNotEmpty) {
          channels = channels.where((c) => c.categoryId == categoryId).toList();
        }
        return channels;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Category>> getVodCategories(XtreamCredentials creds) async {
    try {
      final url = Uri.parse('${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_vod_categories');
      final response = await _client.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Category.fromJson(e, type: 'vod')).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Movie>> getVodStreams(XtreamCredentials creds, {String? categoryId}) async {
    try {
      final url = Uri.parse('${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_vod_streams');
      final response = await _client.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        var movies = data.map((e) => Movie.fromXtream(e, creds.baseUrl, creds.username, creds.password)).toList();
        if (categoryId != null && categoryId.isNotEmpty) {
          movies = movies.where((m) => m.categoryId == categoryId).toList();
        }
        return movies;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Category>> getSeriesCategories(XtreamCredentials creds) async {
    try {
      final url = Uri.parse('${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_series_categories');
      final response = await _client.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Category.fromJson(e, type: 'series')).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Series>> getSeriesList(XtreamCredentials creds, {String? categoryId}) async {
    try {
      final url = Uri.parse('${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_series');
      final response = await _client.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        var seriesList = data.map((e) => Series.fromXtream(e)).toList();
        if (categoryId != null && categoryId.isNotEmpty) {
          seriesList = seriesList.where((s) => s.categoryId == categoryId).toList();
        }
        return seriesList;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<SeriesInfo?> getSeriesInfo(XtreamCredentials creds, String seriesId) async {
    try {
      final url = Uri.parse('${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_series_info&series_id=$seriesId');
      final response = await _client.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final seriesData = data['info'] ?? {};
        final episodesData = data['episodes'] ?? {};

        final series = Series.fromXtream({
          ...seriesData,
          'series_id': seriesId,
        });

        final Map<String, List<SeriesEpisode>> seasons = {};
        episodesData.forEach((seasonNum, episodes) {
          if (episodes is List) {
            seasons[seasonNum.toString()] = episodes
                .map((e) => SeriesEpisode.fromXtream(e, creds.baseUrl, creds.username, creds.password))
                .toList();
          }
        });

        return SeriesInfo(series: series, seasons: seasons);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getM3uPlaylist(String url) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
