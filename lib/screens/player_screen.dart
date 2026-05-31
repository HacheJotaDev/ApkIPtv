import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String url;
  final String type;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.url,
    this.type = 'live',
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;

  bool _hasError = false;
  String _errorMessage = '';
  bool _isPlaying = false;
  bool _isBuffering = true;
  bool _showControls = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Timer? _hideControlsTimer;
  Timer? _retryTimer;
  bool _isDisposed = false;
  bool _isLiveStream = false;
  StreamSubscription? _playingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _bufferingSub;

  // Accent color
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color accentDark = Color(0xFF0097A7);

  @override
  void initState() {
    super.initState();

    // Detect live stream from URL or type
    _isLiveStream = widget.type == 'live' ||
        widget.url.toLowerCase().contains('.m3u8') ||
        widget.url.toLowerCase().contains('/live/');

    _player = Player(configuration: PlayerConfiguration(
      title: widget.title,
      ready: () {
        debugPrint('Player ready for: ${widget.title}');
      },
    ));

    _controller = VideoController(_player);

    WakelockPlus.enable();
    _setupListeners();
    _initPlayer();
    _startHideControlsTimer();
  }

  void _setupListeners() {
    _playingSub = _player.stream.playing.listen((playing) {
      if (mounted && !_isDisposed) {
        setState(() => _isPlaying = playing);
        if (playing) _startHideControlsTimer();
      }
    });

    _errorSub = _player.stream.error.listen((error) {
      if (mounted && !_isDisposed && error.isNotEmpty) {
        debugPrint('Player error: $error');
        if (_retryCount < _maxRetries) {
          _retryCount++;
          debugPrint('Auto-retry attempt $_retryCount/$_maxRetries');
          _retryTimer?.cancel();
          _retryTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && !_isDisposed) _retryPlayback();
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = _getFriendlyError(error);
            _isBuffering = false;
          });
        }
      }
    });

    _positionSub = _player.stream.position.listen((position) {
      if (mounted && !_isDisposed) {
        setState(() => _position = position);
      }
    });

    _durationSub = _player.stream.duration.listen((duration) {
      if (mounted && !_isDisposed) {
        // For live HLS streams, ignore short duration reports
        // These are just the first .ts segment duration, not the total video length
        if (_isLiveStream && duration.inSeconds > 0 && duration.inSeconds < 120) {
          debugPrint('Live stream: ignoring short duration report of ${duration.inSeconds}s');
          return;
        }
        setState(() => _duration = duration);
      }
    });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      if (mounted && !_isDisposed) {
        setState(() => _isBuffering = buffering);
        if (buffering) {
          _cancelHideControlsTimer();
        } else if (_isPlaying) {
          _startHideControlsTimer();
        }
      }
    });
  }

  String _getFriendlyError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Tiempo de espera agotado. El servidor tarda demasiado en responder.';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'Acceso denegado. El servidor rechazo la conexion.';
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return 'Canal no encontrado. El stream ya no esta disponible.';
    }
    if (lower.contains('network') || lower.contains('connection') || lower.contains('socket')) {
      return 'Error de red. Verifica tu conexion a internet.';
    }
    if (lower.contains('format') || lower.contains('codec') || lower.contains('decode')) {
      return 'Formato no soportado. Intenta reintentar la reproduccion.';
    }
    if (lower.contains('eof') || lower.contains('end of file')) {
      return 'El stream se ha cerrado inesperadamente.';
    }
    return 'Error al reproducir. Intenta reintentar.';
  }

  /// Set MPV properties for HLS live streams via platform player
  void _setLiveStreamProperties() {
    try {
      final platform = _player.platform;
      if (platform != null) {
        // Use dynamic to access NativePlayer.setProperty without importing
        // the private class. At runtime on Android, platform IS NativePlayer.
        (platform as dynamic).setProperty('force-seekable', 'no');
        (platform as dynamic).setProperty('cache', 'yes');
        (platform as dynamic).setProperty('demux-max-bytes', '100MiB');
        (platform as dynamic).setProperty('demux-max-back-bytes', '50MiB');
        debugPrint('Live stream MPV properties set successfully');
      } else {
        debugPrint('Platform player not available, cannot set MPV properties');
      }
    } catch (e) {
      debugPrint('MPV property set error (non-fatal): $e');
    }
  }

  Future<void> _initPlayer() async {
    try {
      // For live streams, set MPV properties to handle HLS properly
      // This prevents the 10-second pause bug where mpv thinks the first
      // .ts segment is the entire video
      if (_isLiveStream) {
        _setLiveStreamProperties();
      }

      final media = Media(
        widget.url,
        httpHeaders: {
          'User-Agent': 'XTREAM-IPTV/2.0',
          'Icy-MetaData': '1',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      );
      await _player.open(media);
      await _player.play();
      await _player.setVolume(_volume * 100);
    } catch (e) {
      if (mounted && !_isDisposed) {
        debugPrint('Init player error: $e');
        if (_retryCount < _maxRetries) {
          _retryCount++;
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: 3 * _retryCount), () {
            if (mounted && !_isDisposed) _retryPlayback();
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = _getFriendlyError(e.toString());
            _isBuffering = false;
          });
        }
      }
    }
  }

  Future<void> _retryPlayback() async {
    if (_isDisposed) return;
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isBuffering = true;
    });
    try {
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 800));

      if (_isLiveStream) {
        _setLiveStreamProperties();
      }

      final media = Media(
        widget.url,
        httpHeaders: {
          'User-Agent': 'XTREAM-IPTV/2.0',
          'Icy-MetaData': '1',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      );
      await _player.open(media);
      await _player.play();
    } catch (e) {
      if (mounted && !_isDisposed) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: 3 * _retryCount), () {
            if (mounted && !_isDisposed) _retryPlayback();
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = _getFriendlyError(e.toString());
            _isBuffering = false;
          });
        }
      }
    }
  }

  void _startHideControlsTimer() {
    _cancelHideControlsTimer();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isDisposed && _isPlaying && !_isBuffering) {
        setState(() => _showControls = false);
      }
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _cancelHideControlsTimer();
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelHideControlsTimer();
    _retryTimer?.cancel();
    _playingSub?.cancel();
    _errorSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _bufferingSub?.cancel();
    _player.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WillPopScope(
        onWillPop: () async {
          WakelockPlus.disable();
          return true;
        },
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Video player
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Video(controller: _controller),
                ),
              ),

              // Buffering indicator
              if (_isBuffering && !_hasError)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: accentColor,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _retryCount > 0 ? 'Reintentando...' : 'Cargando...',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

              // Top bar
              if (_showControls || !_isPlaying)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xBB000000), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isLiveStream)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
                              color: const Color(0xFF1A1D30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFF2A2D4A)),
                              ),
                              onSelected: (value) {
                                switch (value) {
                                  case 'retry': _retryCount = 0; _retryPlayback(); break;
                                  case 'speed_05': _player.setRate(0.5); setState(() => _speed = 0.5); break;
                                  case 'speed_075': _player.setRate(0.75); setState(() => _speed = 0.75); break;
                                  case 'speed_1': _player.setRate(1.0); setState(() => _speed = 1.0); break;
                                  case 'speed_125': _player.setRate(1.25); setState(() => _speed = 1.25); break;
                                  case 'speed_15': _player.setRate(1.5); setState(() => _speed = 1.5); break;
                                  case 'speed_2': _player.setRate(2.0); setState(() => _speed = 2.0); break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'retry', child: Row(children: [Icon(Icons.refresh, color: accentColor, size: 20), SizedBox(width: 12), Text('Reintentar', style: TextStyle(color: Colors.white))])),
                                if (!_isLiveStream) ...[
                                  const PopupMenuDivider(),
                                  PopupMenuItem(child: Row(children: [const Icon(Icons.speed, color: accentColor, size: 20), const SizedBox(width: 12), Text('Velocidad: ${_speed}x', style: const TextStyle(color: Colors.white70))])),
                                  ...[('speed_05', '0.5x'), ('speed_075', '0.75x'), ('speed_1', '1.0x (Normal)'), ('speed_125', '1.25x'), ('speed_15', '1.5x'), ('speed_2', '2.0x')].map((e) => PopupMenuItem(
                                    value: e.$1,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 52),
                                      child: Text(e.$2, style: TextStyle(
                                        color: _speed == double.parse(e.$1.replaceAll('speed_', '').replaceAll('_', '.')) ? accentColor : Colors.white70,
                                        fontWeight: _speed == double.parse(e.$1.replaceAll('speed_', '').replaceAll('_', '.')) ? FontWeight.bold : FontWeight.normal,
                                      )),
                                    ),
                                  )),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Center play/pause
              if (!_hasError && !_isBuffering && (_showControls || !_isPlaying))
                Center(
                  child: GestureDetector(
                    onTap: () => _player.playOrPause(),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [accentColor, accentDark]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF0A0E21), size: 52),
                    ),
                  ),
                ),

              // Bottom controls for VOD
              if (_showControls && !_isLiveStream && _duration > Duration.zero)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xBB000000), Colors.transparent]),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              trackShape: const CustomTrackShape(),
                              overlayColor: accentColor.withOpacity(0.2),
                              activeTrackColor: accentColor,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: accentColor,
                            ),
                            child: Slider(
                              value: _duration.inMilliseconds > 0 ? _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()) : 0.0,
                              min: 0.0,
                              max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                              onChanged: (value) => _player.seek(Duration(milliseconds: value.toInt())),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 22), onPressed: () { final newPos = _position - const Duration(seconds: 10); _player.seek(newPos < Duration.zero ? Duration.zero : newPos); })),
                                  const SizedBox(width: 4),
                                  Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28), onPressed: () => _player.playOrPause())),
                                  const SizedBox(width: 4),
                                  Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 22), onPressed: () { final newPos = _position + const Duration(seconds: 10); _player.seek(newPos > _duration ? _duration : newPos); })),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_speed != 1.0) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: accentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text('${_speed}x', style: const TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 8),
                                  Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Live stream bottom bar - just play/pause and retry
              if (_showControls && _isLiveStream && !_hasError)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xBB000000), Colors.transparent]),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                              onPressed: () => _player.playOrPause(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                              onPressed: () { _retryCount = 0; _retryPlayback(); },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Error overlay
              if (_hasError)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    margin: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121421),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.error_outline, color: Colors.red, size: 36)),
                        const SizedBox(height: 16),
                        const Text('Error al reproducir', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [accentColor, accentDark])),
                          child: ElevatedButton.icon(
                            onPressed: () { _retryCount = 0; setState(() { _hasError = false; _errorMessage = ''; _isBuffering = true; }); _retryPlayback(); },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: const Color(0xFF0A0E21), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            icon: const Icon(Icons.refresh, size: 18), label: const Text('REINTENTAR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  const CustomTrackShape();
  @override
  Rect getPreferredRect({required RenderBox parentBox, Offset offset = Offset.zero, required SliderThemeData sliderTheme, bool isEnabled = false, bool isDiscrete = false}) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
