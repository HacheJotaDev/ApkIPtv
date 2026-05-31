import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/xtream_credentials.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../services/xtream_service.dart';
import '../services/m3u_parser.dart';

class IptvProvider extends ChangeNotifier {
  final XtreamService _xtreamService = XtreamService();

  // Auth state
  XtreamCredentials? _credentials;
  XtreamCredentials? get credentials => _credentials;
  Map<String, dynamic>? _userInfo;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  String _connectionType = 'xtream';
  String get connectionType => _connectionType;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Live TV
  List<Category> _liveCategories = [];
  List<Category> get liveCategories => _liveCategories;
  List<Channel> _liveChannels = [];
  List<Channel> get liveChannels => _liveChannels;
  List<Channel> _allLiveChannels = []; // Master list - never filtered
  String? _selectedLiveCategory;
  String? get selectedLiveCategory => _selectedLiveCategory;

  // VOD (Movies)
  List<Category> _vodCategories = [];
  List<Category> get vodCategories => _vodCategories;
  List<Movie> _vodMovies = [];
  List<Movie> get vodMovies => _vodMovies;
  List<Movie> _allVodMovies = []; // Master list - never filtered
  String? _selectedVodCategory;
  String? get selectedVodCategory => _selectedVodCategory;

  // Series
  List<Category> _seriesCategories = [];
  List<Category> get seriesCategories => _seriesCategories;
  List<Series> _seriesList = [];
  List<Series> get seriesList => _seriesList;
  String? _selectedSeriesCategory;
  String? get selectedSeriesCategory => _selectedSeriesCategory;

  // Search
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<Channel> get filteredLiveChannels {
    var result = _liveChannels;
    if (_searchQuery.isNotEmpty) {
      result = result.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return result;
  }

  List<Movie> get filteredVodMovies {
    var result = _vodMovies;
    if (_searchQuery.isNotEmpty) {
      result = result.where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return result;
  }

  List<Series> get filteredSeriesList {
    var result = _seriesList;
    if (_searchQuery.isNotEmpty) {
      result = result.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return result;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Test basic server connectivity before attempting login
  Future<String> testServerConnection(String serverUrl) async {
    return await _xtreamService.testConnection(serverUrl);
  }

  // Auth methods
  Future<bool> loginWithXtream(String server, String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final creds = XtreamCredentials(server: server, username: username, password: password);

      // First test connectivity
      final connResult = await _xtreamService.testConnection(creds.baseUrl);
      if (connResult != 'ok') {
        _errorMessage = connResult;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final data = await _xtreamService.authenticate(creds);
      if (data != null) {
        _credentials = creds;
        _userInfo = data['user_info'];
        _isAuthenticated = true;
        _connectionType = 'xtream';
        await _saveCredentials(creds);
        await _loadAllContent();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Credenciales incorrectas o servidor no disponible';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on SocketException catch (e) {
      _errorMessage = 'Sin conexion a internet. Verifica tu red. (${e.message})';
      _isLoading = false;
      notifyListeners();
      return false;
    } on HandshakeException catch (e) {
      _errorMessage = 'Error de certificado SSL. Intenta usar HTTP en lugar de HTTPS. (${e.message})';
      _isLoading = false;
      notifyListeners();
      return false;
    } on FormatException catch (e) {
      _errorMessage = 'URL del servidor invalida. Verifica el formato. (${e.message})';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error de conexion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithM3u(String url) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final content = await _xtreamService.getM3uPlaylist(url);
      if (content != null && content.trim().isNotEmpty) {
        // Check if it looks like an M3U file
        final trimmedContent = content.trim();
        if (!trimmedContent.startsWith('#EXTM3U') && !trimmedContent.startsWith('#EXTINF')) {
          _errorMessage = 'El contenido no parece ser una lista M3U valida. Verifica la URL.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final parsed = M3uParser.parseM3u(content);
        _liveChannels = List<Channel>.from(parsed['channels']);
        _allLiveChannels = List.from(_liveChannels);
        _vodMovies = List<Movie>.from(parsed['movies']);
        _allVodMovies = List.from(_vodMovies);
        _liveCategories = List<Category>.from(parsed['categories'].where((c) => c.type == 'live'));
        _vodCategories = List<Category>.from(parsed['categories'].where((c) => c.type == 'vod'));
        _connectionType = 'm3u';
        _isAuthenticated = true;
        await _saveM3uUrl(url);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'No se pudo cargar la lista M3U. Verifica la URL y tu conexion.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on SocketException catch (e) {
      _errorMessage = 'Sin conexion a internet. Verifica tu red. (${e.message})';
      _isLoading = false;
      notifyListeners();
      return false;
    } on HandshakeException catch (e) {
      _errorMessage = 'Error de certificado SSL. Intenta usar HTTP en lugar de HTTPS. (${e.message})';
      _isLoading = false;
      notifyListeners();
      return false;
    } on FormatException catch (e) {
      _errorMessage = 'URL de la lista M3U invalida. Verifica el formato. (${e.message})';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al cargar M3U: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadAllContent() async {
    if (_credentials == null) return;

    // Load categories first
    _liveCategories = await _xtreamService.getLiveCategories(_credentials!);
    _vodCategories = await _xtreamService.getVodCategories(_credentials!);
    _seriesCategories = await _xtreamService.getSeriesCategories(_credentials!);
    notifyListeners();

    // Load streams into master lists
    _liveChannels = await _xtreamService.getLiveStreams(_credentials!);
    _allLiveChannels = List.from(_liveChannels);
    _vodMovies = await _xtreamService.getVodStreams(_credentials!);
    _allVodMovies = List.from(_vodMovies);
    _seriesList = await _xtreamService.getSeriesList(_credentials!);
    notifyListeners();
  }

  Future<void> selectLiveCategory(String? categoryId) async {
    _selectedLiveCategory = categoryId;
    _isLoading = true;
    notifyListeners();

    if (_connectionType == 'xtream' && _credentials != null) {
      if (categoryId == null) {
        _liveChannels = List.from(_allLiveChannels);
      } else {
        _liveChannels = _allLiveChannels.where((c) => c.categoryId == categoryId).toList();
        if (_liveChannels.isEmpty) {
          final apiChannels = await _xtreamService.getLiveStreams(_credentials!, categoryId: categoryId);
          if (apiChannels.isNotEmpty) {
            _liveChannels = apiChannels;
          }
        }
      }
    } else {
      if (categoryId != null) {
        _liveChannels = _allLiveChannels.where((c) => c.categoryId == categoryId).toList();
      } else {
        _liveChannels = List.from(_allLiveChannels);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectVodCategory(String? categoryId) async {
    _selectedVodCategory = categoryId;
    _isLoading = true;
    notifyListeners();

    if (_connectionType == 'xtream' && _credentials != null) {
      if (categoryId == null) {
        // "All" selected - show all movies from master list
        _vodMovies = List.from(_allVodMovies);
      } else {
        // Filter locally from master list instead of making a new API call
        // This prevents movies from disappearing when the API returns empty
        _vodMovies = _allVodMovies.where((m) => m.categoryId == categoryId).toList();
        // If local filter returns nothing, try API as fallback
        if (_vodMovies.isEmpty) {
          final apiMovies = await _xtreamService.getVodStreams(_credentials!, categoryId: categoryId);
          if (apiMovies.isNotEmpty) {
            _vodMovies = apiMovies;
          }
        }
      }
    } else {
      if (categoryId != null) {
        _vodMovies = _allVodMovies.where((m) => m.categoryId == categoryId).toList();
      } else {
        _vodMovies = List.from(_allVodMovies);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectSeriesCategory(String? categoryId) async {
    _selectedSeriesCategory = categoryId;
    _isLoading = true;
    notifyListeners();

    if (_connectionType == 'xtream' && _credentials != null) {
      _seriesList = await _xtreamService.getSeriesList(_credentials!, categoryId: categoryId);
    } else {
      if (categoryId != null) {
        _seriesList = _seriesList.where((s) => s.categoryId == categoryId).toList();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<SeriesInfo?> getSeriesInfo(String seriesId) async {
    if (_credentials == null) return null;
    return _xtreamService.getSeriesInfo(_credentials!, seriesId);
  }

  // Persistence
  Future<void> _saveCredentials(XtreamCredentials creds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('xtream_creds', json.encode(creds.toJson()));
    await prefs.setString('connection_type', 'xtream');
  }

  Future<void> _saveM3uUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('m3u_url', url);
    await prefs.setString('connection_type', 'm3u');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('connection_type');

    if (type == 'xtream') {
      final credsStr = prefs.getString('xtream_creds');
      if (credsStr != null) {
        final creds = XtreamCredentials.fromJson(json.decode(credsStr));
        return await loginWithXtream(creds.server, creds.username, creds.password);
      }
    } else if (type == 'm3u') {
      final url = prefs.getString('m3u_url');
      if (url != null) {
        return await loginWithM3u(url);
      }
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _credentials = null;
    _userInfo = null;
    _isAuthenticated = false;
    _connectionType = 'xtream';
    _liveCategories = [];
    _liveChannels = [];
    _allLiveChannels = [];
    _vodCategories = [];
    _vodMovies = [];
    _allVodMovies = [];
    _seriesCategories = [];
    _seriesList = [];
    _selectedLiveCategory = null;
    _selectedVodCategory = null;
    _selectedSeriesCategory = null;
    _searchQuery = '';
    _xtreamService.dispose();
    notifyListeners();
  }
}
