import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service for Google Cast (Chromecast) integration
/// Communicates with native Android code via MethodChannel
class CastService with ChangeNotifier {
  static const MethodChannel _castChannel = MethodChannel('com.hj.xtream.iptv/cast');
  static const EventChannel _castStateChannel = EventChannel('com.hj.xtream.iptv/cast_state');

  String _castState = 'disconnected'; // disconnected, connecting, connected, unavailable, error, suspended
  String get castState => _castState;
  bool get isConnected => _castState == 'connected';
  bool get isConnecting => _castState == 'connecting';
  bool get isAvailable => _castState != 'unavailable';
  bool get isUnavailable => _castState == 'unavailable';

  StreamSubscription? _stateSubscription;

  CastService() {
    _init();
  }

  void _init() {
    if (!Platform.isAndroid) {
      _castState = 'unavailable';
      notifyListeners();
      return;
    }

    _stateSubscription = _castStateChannel.receiveBroadcastStream().listen(
      (dynamic state) {
        if (state is String) {
          _castState = state;
          notifyListeners();
        }
      },
      onError: (dynamic error) {
        debugPrint('Cast state stream error: $error');
        _castState = 'unavailable';
        notifyListeners();
      },
    );

    // Get initial state
    getCastState();
  }

  Future<bool> isAvailableOnDevice() async {
    if (!Platform.isAndroid) return false;
    try {
      final available = await _castChannel.invokeMethod<bool>('isAvailable');
      return available ?? false;
    } on PlatformException catch (e) {
      debugPrint('Cast availability check failed: ${e.message}');
      return false;
    }
  }

  Future<String> getCastState() async {
    if (!Platform.isAndroid) return 'unavailable';
    try {
      final state = await _castChannel.invokeMethod<String>('getCastState');
      if (state != null) {
        _castState = state;
        notifyListeners();
      }
      return state ?? 'unavailable';
    } on PlatformException catch (e) {
      debugPrint('Get cast state failed: ${e.message}');
      return 'unavailable';
    }
  }

  /// Load media to the connected Cast device
  Future<bool> loadMedia({
    required String url,
    required String title,
    String subtitle = '',
    String contentType = 'video/mp4',
    String imageUrl = '',
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _castChannel.invokeMethod<bool>('loadMedia', {
        'url': url,
        'title': title,
        'subtitle': subtitle,
        'contentType': _determineContentType(url, contentType),
        'imageUrl': imageUrl,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Load media to Cast failed: ${e.message}');
      return false;
    }
  }

  Future<void> play() async {
    if (!Platform.isAndroid) return;
    try {
      await _castChannel.invokeMethod<bool>('play');
    } on PlatformException catch (e) {
      debugPrint('Cast play failed: ${e.message}');
    }
  }

  Future<void> pause() async {
    if (!Platform.isAndroid) return;
    try {
      await _castChannel.invokeMethod<bool>('pause');
    } on PlatformException catch (e) {
      debugPrint('Cast pause failed: ${e.message}');
    }
  }

  Future<void> seekTo(int positionMs) async {
    if (!Platform.isAndroid) return;
    try {
      await _castChannel.invokeMethod<bool>('seekTo', {'position': positionMs});
    } on PlatformException catch (e) {
      debugPrint('Cast seek failed: ${e.message}');
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _castChannel.invokeMethod<bool>('stop');
    } on PlatformException catch (e) {
      debugPrint('Cast stop failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>?> getPlaybackStatus() async {
    if (!Platform.isAndroid) return null;
    try {
      final status = await _castChannel.invokeMethod<Map>('getPlaybackStatus');
      return status?.cast<String, dynamic>();
    } on PlatformException catch (e) {
      debugPrint('Get playback status failed: ${e.message}');
      return null;
    }
  }

  Future<void> endSession() async {
    if (!Platform.isAndroid) return;
    try {
      await _castChannel.invokeMethod<bool>('endSession');
    } on PlatformException catch (e) {
      debugPrint('End cast session failed: ${e.message}');
    }
  }

  /// Determine content type based on URL
  String _determineContentType(String url, String fallback) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8')) return 'application/x-mpegurl';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.ts')) return 'video/mp2t';
    if (lower.endsWith('.flv')) return 'video/x-flv';
    if (lower.endsWith('.avi')) return 'video/x-msvideo';
    // For live streams (common IPTV pattern)
    if (lower.contains('/live/')) return 'application/x-mpegurl';
    return fallback;
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }
}
