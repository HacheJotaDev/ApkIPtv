import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iptv_models.dart';
import '../services/iptv_service.dart';

class AppState extends ChangeNotifier {
  final SharedPreferences _prefs;
  final IptvService _service = IptvService();
  
  XtreamCredentials? _credentials;
  List<Channel> _channels = [];
  List<VodItem> _movies = [];
  List<VodItem> _series = [];
  List<String> _favoriteIds = [];
  String _connectionType = 'xtream';
  String _m3uUrl = '';
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;
  List<String> _channelGroups = [];
  List<String> _movieGroups = [];
  List<String> _seriesGroups = [];
  String _selectedChannelGroup = 'Todos';
  String _selectedMovieGroup = 'Todos';
  String _selectedSeriesGroup = 'Todos';
  String _searchQuery = '';
  String _statusMessage = '';

  AppState(this._prefs) {
    _loadSavedState();
  }

  // Getters
  XtreamCredentials? get credentials => _credentials;
  List<Channel> get channels => _channels;
  List<VodItem> get movies => _movies;
  List<VodItem> get series => _series;
  List<String> get favoriteIds => _favoriteIds;
  String get connectionType => _connectionType;
  String get m3uUrl => _m3uUrl;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;
  List<String> get channelGroups => _channelGroups;
  List<String> get movieGroups => _movieGroups;
  List<String> get seriesGroups => _seriesGroups;
  String get selectedChannelGroup => _selectedChannelGroup;
  String get selectedMovieGroup => _selectedMovieGroup;
  String get selectedSeriesGroup => _selectedSeriesGroup;
  String get searchQuery => _searchQuery;
  String get statusMessage => _statusMessage;
  
  bool get hasConnection => _credentials != null || _m3uUrl.isNotEmpty;
  
  List<Channel> get filteredChannels {
    var result = _channels;
    if (_selectedChannelGroup != 'Todos') {
      result = result.where((c) => c.group == _selectedChannelGroup).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    return result;
  }
  
  List<VodItem> get filteredMovies {
    var result = _movies;
    if (_selectedMovieGroup != 'Todos') {
      result = result.where((v) => v.group == _selectedMovieGroup).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((v) => v.name.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  List<VodItem> get filteredSeries {
    var result = _series;
    if (_selectedSeriesGroup != 'Todos') {
      result = result.where((v) => v.group == _selectedSeriesGroup).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((v) => v.name.toLowerCase().contains(q)).toList();
    }
    return result;
  }
  
  List<Channel> get favoriteChannels => _channels.where((c) => c.isFavorite).toList();
  List<VodItem> get favoriteMovies => _movies.where((v) => v.isFavorite).toList();
  List<VodItem> get favoriteSeries => _series.where((v) => v.isFavorite).toList();

  IptvService get service => _service;

  void _loadSavedState() {
    final credsJson = _prefs.getString('xtream_credentials');
    if (credsJson != null) {
      _credentials = XtreamCredentials.fromJson(json.decode(credsJson));
    }
    _connectionType = _prefs.getString('connection_type') ?? 'xtream';
    _m3uUrl = _prefs.getString('m3u_url') ?? '';
    _favoriteIds = _prefs.getStringList('favorite_ids') ?? [];
    notifyListeners();
  }

  Future<void> setXtreamCredentials(String server, String username, String password) async {
    _credentials = XtreamCredentials(server: server, username: username, password: password);
    _connectionType = 'xtream';
    await _prefs.setString('xtream_credentials', json.encode(_credentials!.toJson()));
    await _prefs.setString('connection_type', 'xtream');
    notifyListeners();
  }

  Future<void> setM3uUrl(String url) async {
    _m3uUrl = url;
    _connectionType = 'm3u';
    await _prefs.setString('m3u_url', url);
    await _prefs.setString('connection_type', 'm3u');
    notifyListeners();
  }

  void setSelectedChannelGroup(String group) {
    _selectedChannelGroup = group;
    notifyListeners();
  }

  void setSelectedMovieGroup(String group) {
    _selectedMovieGroup = group;
    notifyListeners();
  }

  void setSelectedSeriesGroup(String group) {
    _selectedSeriesGroup = group;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusMessage(String msg) {
    _statusMessage = msg;
    notifyListeners();
  }

  Future<void> toggleFavoriteChannel(String channelId) async {
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx >= 0) {
      _channels[idx].isFavorite = !_channels[idx].isFavorite;
      if (_channels[idx].isFavorite) {
        _favoriteIds.add(channelId);
      } else {
        _favoriteIds.remove(channelId);
      }
      await _prefs.setStringList('favorite_ids', _favoriteIds);
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteVod(String vodId) async {
    var idx = _movies.indexWhere((v) => v.id == vodId);
    if (idx >= 0) {
      _movies[idx].isFavorite = !_movies[idx].isFavorite;
      if (_movies[idx].isFavorite) {
        _favoriteIds.add(vodId);
      } else {
        _favoriteIds.remove(vodId);
      }
      await _prefs.setStringList('favorite_ids', _favoriteIds);
      notifyListeners();
      return;
    }
    idx = _series.indexWhere((v) => v.id == vodId);
    if (idx >= 0) {
      _series[idx].isFavorite = !_series[idx].isFavorite;
      if (_series[idx].isFavorite) {
        _favoriteIds.add(vodId);
      } else {
        _favoriteIds.remove(vodId);
      }
      await _prefs.setStringList('favorite_ids', _favoriteIds);
      notifyListeners();
    }
  }

  void setChannels(List<Channel> channels) {
    _channels = channels;
    for (var channel in _channels) {
      if (_favoriteIds.contains(channel.id)) {
        channel.isFavorite = true;
      }
    }
    _channelGroups = ['Todos', ...{..._channels.map((c) => c.group ?? 'Sin Grupo').where((g) => g.isNotEmpty)}];
    notifyListeners();
  }

  void setMovies(List<VodItem> items) {
    _movies = items;
    for (var item in _movies) {
      if (_favoriteIds.contains(item.id)) {
        item.isFavorite = true;
      }
    }
    _movieGroups = ['Todos', ...{..._movies.map((v) => v.group ?? 'Sin Grupo').where((g) => g.isNotEmpty)}];
    notifyListeners();
  }

  void setSeries(List<VodItem> items) {
    _series = items;
    for (var item in _series) {
      if (_favoriteIds.contains(item.id)) {
        item.isFavorite = true;
      }
    }
    _seriesGroups = ['Todos', ...{..._series.map((v) => v.group ?? 'Sin Grupo').where((g) => g.isNotEmpty)}];
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setConnected(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Auto-reconnect using saved credentials on app start
  Future<void> autoReconnect() async {
    if (!hasConnection) return;
    
    setLoading(true);
    setStatusMessage('Conectando...');
    setError(null);
    
    try {
      if (_connectionType == 'xtream' && _credentials != null) {
        final connected = await _service.testXtreamConnection(_credentials!);
        if (!connected) {
          setError('No se pudo conectar al servidor');
          setLoading(false);
          return;
        }
        await _loadXtreamData();
      } else if (_connectionType == 'm3u' && _m3uUrl.isNotEmpty) {
        await _loadM3uData();
      }
    } catch (e) {
      setError('Error al reconectar: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> _loadXtreamData() async {
    final creds = _credentials!;
    setStatusMessage('Cargando canales...');
    
    final results = await Future.wait([
      _service.fetchXtreamLiveChannels(creds),
      _service.fetchXtreamLiveCategories(creds),
      _service.fetchXtreamVod(creds),
      _service.fetchXtreamVodCategories(creds),
      _service.fetchXtreamSeries(creds),
      _service.fetchXtreamSeriesCategories(creds),
    ]);

    final channels = results[0] as List<Channel>;
    final liveCategories = results[1] as Map<String, String>;
    final vodItems = results[2] as List<VodItem>;
    final vodCategories = results[3] as Map<String, String>;
    final seriesItems = results[4] as List<VodItem>;
    final seriesCategories = results[5] as Map<String, String>;

    setChannels(_service.resolveChannelCategories(channels, liveCategories));
    setMovies(_service.resolveVodCategories(vodItems, vodCategories));
    setSeries(_service.resolveVodCategories(seriesItems, seriesCategories));
    setConnected(true);
    setStatusMessage('Cargado: ${channels.length} canales, ${vodItems.length} peliculas, ${seriesItems.length} series');
  }

  Future<void> _loadM3uData() async {
    final results = await _service.parseM3u(_m3uUrl);
    final channels = results[0] as List<Channel>;
    final vodItems = results[1] as List<VodItem>;
    
    // Separate movies from series in M3U (basic heuristic)
    final movies = vodItems.where((v) => v.type != 'series').toList();
    final series = vodItems.where((v) => v.type == 'series').toList();
    
    setChannels(channels);
    setMovies(movies);
    setSeries(series);
    setConnected(true);
    setStatusMessage('Cargado: ${channels.length} canales, ${movies.length} peliculas, ${series.length} series');
  }

  Future<void> disconnect() async {
    _credentials = null;
    _m3uUrl = '';
    _channels = [];
    _movies = [];
    _series = [];
    _channelGroups = [];
    _movieGroups = [];
    _seriesGroups = [];
    _connectionType = 'xtream';
    _isConnected = false;
    _statusMessage = '';
    _error = null;
    await _prefs.remove('xtream_credentials');
    await _prefs.remove('m3u_url');
    await _prefs.remove('connection_type');
    notifyListeners();
  }
}
