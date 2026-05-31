import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/iptv_models.dart';

class IptvService {
  static const Duration _timeout = Duration(seconds: 20);

  /// Test Xtream Codes API connection
  Future<bool> testXtreamConnection(XtreamCredentials creds) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=user'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user_info'] != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get user info from Xtream Codes API
  Future<Map<String, dynamic>?> fetchUserInfo(XtreamCredentials creds) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=user'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch live channels from Xtream Codes API
  Future<List<Channel>> fetchXtreamLiveChannels(XtreamCredentials creds) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=get_live_streams'))
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Channel(
          id: item['stream_id'].toString(),
          name: item['name'] ?? 'Sin Nombre',
          url: '${creds.liveStreamUrl}${item['stream_id']}.m3u8',
          logo: item['stream_icon'],
          group: item['category_id'].toString(),
          epgId: item['epg_channel_id']?.toString(),
        )).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch live categories from Xtream Codes API
  Future<Map<String, String>> fetchXtreamLiveCategories(XtreamCredentials creds) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=get_live_categories'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return {for (var item in data) item['category_id'].toString(): item['category_name'] ?? ''};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Fetch VOD from Xtream Codes API
  Future<List<VodItem>> fetchXtreamVod(XtreamCredentials creds) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=get_vod_streams'))
          .timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VodItem(
          id: item['stream_id'].toString(),
          name: item['name'] ?? 'Sin Nombre',
          url: '${creds.vodStreamUrl}${item['stream_id']}.${item['container_extension'] ?? 'mp4'}',
          poster: item['stream_icon'],
          group: item['category_id'].toString(),
          rating: item['rating']?.toString(),
          year: item['year']?.toString(),
          plot: item['plot'],
          duration: item['duration']?.toString(),
          director: item['director'],
          cast: item['cast'],
          genre: item['genre'],
          releaseDate: item['releaseDate'],
          type: 'movie',
        )).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch VOD categories
  Future<Map<String, String>> fetchXtreamVodCategories(XtreamCredentials creds) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=get_vod_categories'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return {for (var item in data) item['category_id'].toString(): item['category_name'] ?? ''};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Fetch series from Xtream Codes API
  Future<List<VodItem>> fetchXtreamSeries(XtreamCredentials creds) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=get_series'))
          .timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VodItem(
          id: item['series_id'].toString(),
          name: item['name'] ?? 'Sin Nombre',
          url: '${creds.seriesStreamUrl}${item['series_id']}',
          poster: item['cover'],
          group: item['category_id'].toString(),
          rating: item['rating']?.toString(),
          year: item['year']?.toString(),
          plot: item['plot'],
          genre: item['genre'],
          cast: item['cast'],
          director: item['director'],
          releaseDate: item['releaseDate'],
          type: 'series',
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch series categories
  Future<Map<String, String>> fetchXtreamSeriesCategories(XtreamCredentials creds) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=get_series_categories'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return {for (var item in data) item['category_id'].toString(): item['category_name'] ?? ''};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Fetch series info (seasons and episodes)
  Future<List<SeriesSeason>> fetchSeriesInfo(XtreamCredentials creds, String seriesId) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=get_series_info&series_id=$seriesId'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final episodes = data['episodes'] as Map<String, dynamic>?;
        
        if (episodes == null) return [];
        
        final List<SeriesSeason> seasons = [];
        
        for (var entry in episodes.entries) {
          final seasonNum = entry.key;
          final episodeList = entry.value as List<dynamic>;
          
          seasons.add(SeriesSeason(
            seasonId: seasonNum,
            name: 'Temporada $seasonNum',
            episodes: episodeList.map((ep) => Episode(
              id: ep['id']?.toString() ?? '',
              title: ep['title']?.toString() ?? 'Episodio',
              url: '${creds.seriesStreamUrl}${ep['id']}.${ep['container_extension'] ?? 'mp4'}',
              episodeNum: ep['episode_num'] is int ? ep['episode_num'] : int.tryParse(ep['episode_num']?.toString() ?? ''),
              thumbnail: ep['info']?['image'] ?? ep['container_extension'],
              plot: ep['info']?['plot'],
              durationSeconds: (ep['info']?['duration_secs'] is num) 
                  ? (ep['info']?['duration_secs'] as num).toDouble() 
                  : null,
            )).toList(),
          ));
        }
        
        return seasons;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch VOD stream info (for detailed movie info)
  Future<VodItem?> fetchVodInfo(XtreamCredentials creds, String vodId) async {
    try {
      final response = await http
          .get(Uri.parse('${creds.playerApi}&action=get_vod_info&vod_id=$vodId'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final info = data['info'] as Map<String, dynamic>?;
        final movieData = data['movie_data'] as Map<String, dynamic>?;
        
        if (info == null) return null;
        
        return VodItem(
          id: vodId,
          name: info['name']?.toString() ?? '',
          url: '${creds.vodStreamUrl}$vodId.${movieData?['container_extension'] ?? 'mp4'}',
          poster: info['movie_image'] ?? info['cover'],
          group: info['category_id']?.toString(),
          rating: info['rating']?.toString(),
          year: info['year']?.toString(),
          plot: info['plot'],
          duration: info['duration']?.toString(),
          director: info['director'],
          cast: info['cast'],
          genre: info['genre'],
          releaseDate: info['releaseDate'],
          type: 'movie',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse M3U playlist
  Future<List<dynamic>> parseM3u(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) throw Exception('Error al descargar la lista M3U');
      
      final lines = response.body.split('\n');
      final List<Channel> channels = [];
      final List<VodItem> vodItems = [];
      
      String? currentName;
      String? currentLogo;
      String? currentGroup;
      String? currentEpgId;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        if (line.startsWith('#EXTINF:')) {
          final nameMatch = RegExp(r',(.+)$').firstMatch(line);
          currentName = nameMatch?.group(1)?.trim() ?? 'Sin Nombre';
          
          final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
          currentLogo = logoMatch?.group(1);
          
          final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
          currentGroup = groupMatch?.group(1);
          
          final epgMatch = RegExp(r'tvg-id="([^"]*)"').firstMatch(line);
          currentEpgId = epgMatch?.group(1);
        } else if (line.startsWith('http') && currentName != null) {
          final isLive = line.contains('.m3u8') || 
                        line.contains('/live/') || 
                        currentGroup?.toLowerCase().contains('vivo') == true ||
                        currentGroup?.toLowerCase().contains('live') == true ||
                        currentGroup?.toLowerCase().contains('canal') == true ||
                        currentGroup?.toLowerCase().contains('tv') == true;
          
          final isSeries = currentGroup?.toLowerCase().contains('serie') == true ||
                          currentGroup?.toLowerCase().contains('series') == true;
          
          if (isLive) {
            channels.add(Channel(
              id: 'm3u_ch_${channels.length}',
              name: currentName,
              url: line,
              logo: currentLogo,
              group: currentGroup ?? 'Sin Grupo',
              epgId: currentEpgId,
            ));
          } else {
            vodItems.add(VodItem(
              id: 'm3u_vod_${vodItems.length}',
              name: currentName,
              url: line,
              poster: currentLogo,
              group: currentGroup ?? 'Sin Grupo',
              type: isSeries ? 'series' : 'movie',
            ));
          }
          
          currentName = null;
          currentLogo = null;
          currentGroup = null;
          currentEpgId = null;
        }
      }
      
      return [channels, vodItems];
    } catch (e) {
      rethrow;
    }
  }

  /// Resolve category IDs to names
  List<Channel> resolveChannelCategories(List<Channel> channels, Map<String, String> categories) {
    return channels.map((ch) {
      final groupName = categories[ch.group] ?? ch.group ?? 'Sin Grupo';
      return Channel(
        id: ch.id,
        name: ch.name,
        url: ch.url,
        logo: ch.logo,
        group: groupName,
        epgId: ch.epgId,
        isFavorite: ch.isFavorite,
      );
    }).toList();
  }

  List<VodItem> resolveVodCategories(List<VodItem> items, Map<String, String> categories) {
    return items.map((item) {
      final groupName = categories[item.group] ?? item.group ?? 'Sin Grupo';
      return VodItem(
        id: item.id,
        name: item.name,
        url: item.url,
        poster: item.poster,
        group: groupName,
        rating: item.rating,
        year: item.year,
        plot: item.plot,
        duration: item.duration,
        director: item.director,
        cast: item.cast,
        genre: item.genre,
        releaseDate: item.releaseDate,
        type: item.type,
        isFavorite: item.isFavorite,
      );
    }).toList();
  }
}
