import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _liveKey = 'favorites_live';
  static const String _vodKey = 'favorites_vod';
  static const String _seriesKey = 'favorites_series';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<String>> getFavorites(String type) async {
    final prefs = await _prefs;
    final key = _getKey(type);
    return prefs.getStringList(key) ?? [];
  }

  Future<void> addFavorite(String type, String id) async {
    final prefs = await _prefs;
    final key = _getKey(type);
    final favorites = await getFavorites(type);
    if (!favorites.contains(id)) {
      favorites.add(id);
      await prefs.setStringList(key, favorites);
    }
  }

  Future<void> removeFavorite(String type, String id) async {
    final prefs = await _prefs;
    final key = _getKey(type);
    final favorites = await getFavorites(type);
    favorites.remove(id);
    await prefs.setStringList(key, favorites);
  }

  Future<bool> isFavorite(String type, String id) async {
    final favorites = await getFavorites(type);
    return favorites.contains(id);
  }

  Future<void> toggleFavorite(String type, String id) async {
    if (await isFavorite(type, id)) {
      await removeFavorite(type, id);
    } else {
      await addFavorite(type, id);
    }
  }

  String _getKey(String type) {
    switch (type) {
      case 'live':
        return _liveKey;
      case 'vod':
        return _vodKey;
      case 'series':
        return _seriesKey;
      default:
        return _liveKey;
    }
  }
}
