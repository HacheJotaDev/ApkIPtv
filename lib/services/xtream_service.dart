import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/xtream_credentials.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';

class XtreamService {
  http.Client? _client;

  http.Client get _httpClient {
    _client ??= http.Client();
    return _client!;
  }

  void dispose() {
    _client?.close();
    _client = null;
  }

  /// Test basic connectivity to the server (not the full API)
  Future<String> testConnection(String serverUrl) async {
    try {
      String url = serverUrl.trim();
      if (!url.startsWith('http')) {
        url = 'http://$url';
      }
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }

      final uri = Uri.parse(url);
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 302 || response.statusCode == 301) {
        return 'ok';
      } else {
        return 'Servidor respondio con codigo ${response.statusCode}';
      }
    } on SocketException catch (e) {
      return 'No se pudo conectar al servidor. Verifica la URL y tu conexion a internet. (${e.message})';
    } on HandshakeException catch (e) {
      return 'Error de certificado SSL. El servidor podria usar un certificado no valido. (${e.message})';
    } on FormatException catch (e) {
      return 'URL invalida. Verifica el formato del servidor. (${e.message})';
    } catch (e) {
      return 'Error de conexion: $e';
    }
  }

  /// Safely decode JSON response handling encoding issues
  dynamic _safeJsonDecode(String body) {
    String cleanBody = body.trim();
    // Remove BOM if present
    if (cleanBody.startsWith('\uFEFF')) {
      cleanBody = cleanBody.substring(1);
    }
    return json.decode(cleanBody);
  }

  Future<Map<String, dynamic>?> authenticate(XtreamCredentials creds) async {
    try {
      final url = Uri.parse(creds.authUrl);
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return null;

        final data = _safeJsonDecode(body);
        if (data is Map<String, dynamic>) {
          if (data['user_info'] != null && data['user_info']['auth'] == 1) {
            return data;
          }
          // Check if the response contains an error message
          if (data['user_info'] != null && data['user_info']['auth'] == 0) {
            return null; // Invalid credentials
          }
        }
        return null;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return null; // Unauthorized
      } else {
        return null;
      }
    } on SocketException {
      return null;
    } on HandshakeException {
      return null;
    } on FormatException {
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Category>> getLiveCategories(XtreamCredentials creds) async {
    try {
      final url = Uri.parse('${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_live_categories');
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return [];
        final List<dynamic> data = _safeJsonDecode(body);
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
      if (categoryId != null && categoryId.isNotEmpty) {
        urlStr += '&category_id=$categoryId';
      }
      final url = Uri.parse(urlStr);
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
      }).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return [];
        final List<dynamic> data = _safeJsonDecode(body);
        var channels = data.map((e) => Channel.fromXtream(e, creds.baseUrl, creds.username, creds.password)).toList();
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
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return [];
        final List<dynamic> data = _safeJsonDecode(body);
        return data.map((e) => Category.fromJson(e, type: 'vod')).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Movie>> getVodStreams(XtreamCredentials creds, {String? categoryId}) async {
    try {
      var urlStr = '${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_vod_streams';
      if (categoryId != null && categoryId.isNotEmpty) {
        urlStr += '&category_id=$categoryId';
      }
      final url = Uri.parse(urlStr);
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
      }).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return [];
        final List<dynamic> data = _safeJsonDecode(body);
        var movies = data.map((e) => Movie.fromXtream(e, creds.baseUrl, creds.username, creds.password)).toList();
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
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return [];
        final List<dynamic> data = _safeJsonDecode(body);
        return data.map((e) => Category.fromJson(e, type: 'series')).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Series>> getSeriesList(XtreamCredentials creds, {String? categoryId}) async {
    try {
      var urlStr = '${creds.playerApiUrl}?username=${creds.username}&password=${creds.password}&action=get_series';
      if (categoryId != null && categoryId.isNotEmpty) {
        urlStr += '&category_id=$categoryId';
      }
      final url = Uri.parse(urlStr);
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
      }).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return [];
        final List<dynamic> data = _safeJsonDecode(body);
        var seriesList = data.map((e) => Series.fromXtream(e)).toList();
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
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return null;
        final data = _safeJsonDecode(body);
        final seriesData = data['info'] ?? {};
        final episodesData = data['episodes'] ?? {};

        final series = Series.fromXtream({
          ...seriesData,
          'series_id': seriesId,
        });

        final Map<String, List<SeriesEpisode>> seasons = {};
        if (episodesData is Map) {
          episodesData.forEach((seasonNum, episodes) {
            if (episodes is List) {
              seasons[seasonNum.toString()] = episodes
                  .map((e) => SeriesEpisode.fromXtream(e, creds.baseUrl, creds.username, creds.password))
                  .toList();
            }
          });
        }

        return SeriesInfo(series: series, seasons: seasons);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getM3uPlaylist(String url) async {
    try {
      // Clean the URL - handle common issues
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http')) {
        cleanUrl = 'http://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);
      final response = await _httpClient.get(uri, headers: {
        'User-Agent': 'XTREAM-IPTV/1.0',
        'Accept': '*/*',
      }).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // Decode the bytes as UTF-8 to handle encoding properly
        String body;
        try {
          body = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          body = response.body;
        }

        if (body.trim().isEmpty) return null;
        return body;
      }
      return null;
    } on SocketException {
      return null;
    } on HandshakeException {
      return null;
    } on FormatException {
      return null;
    } catch (e) {
      return null;
    }
  }
}
