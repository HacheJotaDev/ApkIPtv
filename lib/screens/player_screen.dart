import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
  static const int _maxRetries = 3;
  Timer? _hideControlsTimer;
  Timer? _retryTimer;
  bool _isDisposed = false;
  StreamSubscription? _playingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _widthSub;
  StreamSubscription? _heightSub;

  @override
  void initState() {
    super.initState();
    _player = Player(configuration: PlayerConfiguration(
      title: widget.title,
      ready: () {
        debugPrint('Player ready for: ${widget.title}');
      },
    ));
    _controller = VideoController(_player);

    // Enable wakelock to keep screen on during playback
    WakelockPlus.enable();

    _setupListeners();
    _initPlayer();

    _startHideControlsTimer();
  }

  void _setupListeners() {
    _playingSub = _player.stream.playing.listen((playing) {
      if (mounted && !_isDisposed) {
        setState(() => _isPlaying = playing);
        if (playing) {
          _startHideControlsTimer();
        }
      }
    });

    _errorSub = _player.stream.error.listen((error) {
      if (mounted && !_isDisposed && error.isNotEmpty) {
        debugPrint('Player error: $error');
        // Auto-retry for live streams on first errors
        if (_retryCount < _maxRetries && widget.type == 'live') {
          _retryCount++;
          debugPrint('Auto-retry attempt $_retryCount/$_maxRetries');
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: 2 * _retryCount), () {
            if (mounted && !_isDisposed) {
              _retryPlayback();
            }
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
        setState(() => _duration = duration);
      }
    });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      if (mounted && !_isDisposed) {
        setState(() => _isBuffering = buffering);
        if (buffering) {
          // While buffering, show controls
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
      return 'Formato no soportado. Intenta abrir con un reproductor externo.';
    }
    if (lower.contains('eof') || lower.contains('end of file')) {
      return 'El stream se ha cerrado inesperadamente.';
    }
    return 'Error al reproducir. Intenta reintentar o usar reproductor externo.';
  }

  Future<void> _initPlayer() async {
    try {
      // Build proper media with HTTP headers for IPTV streams
      final media = Media(
        widget.url,
        httpHeaders: {
          'User-Agent': 'XTREAM-IPTV/2.0',
          'Icy-MetaData': '1',
        },
      );

      await _player.open(media);

      // For live streams, try to start playback immediately
      if (widget.type == 'live') {
        await _player.play();
      }

      // Set initial volume
      await _player.setVolume(_volume * 100);
    } catch (e) {
      if (mounted && !_isDisposed) {
        debugPrint('Init player error: $e');
        // Auto-retry on init failure
        if (_retryCount < _maxRetries) {
          _retryCount++;
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: 2 * _retryCount), () {
            if (mounted && !_isDisposed) {
              _retryPlayback();
            }
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
      await Future.delayed(const Duration(milliseconds: 500));
      final media = Media(
        widget.url,
        httpHeaders: {
          'User-Agent': 'XTREAM-IPTV/2.0',
          'Icy-MetaData': '1',
        },
      );
      await _player.open(media);
      await _player.play();
    } catch (e) {
      if (mounted && !_isDisposed) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: 2 * _retryCount), () {
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

  Future<void> _openWithExternalPlayer() async {
    // Try to open the stream URL with an external player (VLC, MX Player, etc.)
    final uri = Uri.tryParse(widget.url);
    if (uri != null) {
      // Try intent-based launch for Android
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // Fallback: share the URL so user can pick an app
        if (mounted) {
          SharePlus.instance.share(ShareParams(text: widget.url));
        }
      }
    }
  }

  void _shareStreamUrl() {
    SharePlus.instance.share(ShareParams(
      text: '${widget.title}\n${widget.url}',
    ));
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
    _widthSub?.cancel();
    _heightSub?.cancel();
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
              // Video
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
                            color: Color(0xFFF5C518),
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

              // Top bar with gradient
              if (_showControls || !_isPlaying)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
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
                          if (widget.type == 'live')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'EN VIVO',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 6),
                          // Cast/external player button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.cast, color: Color(0xFFF5C518), size: 22),
                              onPressed: _openWithExternalPlayer,
                              tooltip: 'Transmitir a TV',
                            ),
                          ),
                          // More options
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
                                  case 'external':
                                    _openWithExternalPlayer();
                                    break;
                                  case 'share':
                                    _shareStreamUrl();
                                    break;
                                  case 'retry':
                                    _retryCount = 0;
                                    _retryPlayback();
                                    break;
                                  case 'speed_05':
                                    _player.setRate(0.5);
                                    setState(() => _speed = 0.5);
                                    break;
                                  case 'speed_075':
                                    _player.setRate(0.75);
                                    setState(() => _speed = 0.75);
                                    break;
                                  case 'speed_1':
                                    _player.setRate(1.0);
                                    setState(() => _speed = 1.0);
                                    break;
                                  case 'speed_125':
                                    _player.setRate(1.25);
                                    setState(() => _speed = 1.25);
                                    break;
                                  case 'speed_15':
                                    _player.setRate(1.5);
                                    setState(() => _speed = 1.5);
                                    break;
                                  case 'speed_2':
                                    _player.setRate(2.0);
                                    setState(() => _speed = 2.0);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'external',
                                  child: Row(
                                    children: [
                                      Icon(Icons.play_circle_outline, color: Color(0xFFF5C518), size: 20),
                                      SizedBox(width: 12),
                                      Text('Abrir con reproductor externo', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share, color: Color(0xFFF5C518), size: 20),
                                      SizedBox(width: 12),
                                      Text('Compartir enlace del stream', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'retry',
                                  child: Row(
                                    children: [
                                      Icon(Icons.refresh, color: Color(0xFFF5C518), size: 20),
                                      SizedBox(width: 12),
                                      Text('Reintentar reproduccion', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                if (widget.type != 'live') ...[
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.speed, color: Color(0xFFF5C518), size: 20),
                                        const SizedBox(width: 12),
                                        Text('Velocidad: ${_speed}x', style: const TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                  ...[
                                    ('speed_05', '0.5x'),
                                    ('speed_075', '0.75x'),
                                    ('speed_1', '1.0x (Normal)'),
                                    ('speed_125', '1.25x'),
                                    ('speed_15', '1.5x'),
                                    ('speed_2', '2.0x'),
                                  ].map((e) => PopupMenuItem(
                                    value: e.$1,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 52),
                                      child: Text(
                                        e.$2,
                                        style: TextStyle(
                                          color: _speed == double.parse(e.$1.replaceAll('speed_', '').replaceAll('_', '.')) 
                                              ? const Color(0xFFF5C518) 
                                              : Colors.white70,
                                          fontWeight: _speed == double.parse(e.$1.replaceAll('speed_', '').replaceAll('_', '.'))
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
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

              // Center play/pause with glow
              if (!_hasError && !_isBuffering && (_showControls || !_isPlaying))
                Center(
                  child: GestureDetector(
                    onTap: () => _player.playOrPause(),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF5C518), Color(0xFFE5A000)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5C518).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: const Color(0xFF1A1D30),
                        size: 52,
                      ),
                    ),
                  ),
                ),

              // Bottom controls for VOD
              if (_showControls && widget.type != 'live' && _duration > Duration.zero)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xBB000000), Colors.transparent],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress bar
                          SliderTheme(
                            data: SliderThemeData(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              trackShape: const CustomTrackShape(),
                              overlayColor: const Color(0xFFF5C518).withOpacity(0.2),
                              activeTrackColor: const Color(0xFFF5C518),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFFF5C518),
                            ),
                            child: Slider(
                              value: _duration.inMilliseconds > 0
                                  ? _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble())
                                  : 0.0,
                              min: 0.0,
                              max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                              onChanged: (value) {
                                _player.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 10s backward
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.replay_10, color: Colors.white, size: 22),
                                      onPressed: () {
                                        final newPos = _position - const Duration(seconds: 10);
                                        _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Play/pause
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () => _player.playOrPause(),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // 10s forward
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 22),
                                      onPressed: () {
                                        final newPos = _position + const Duration(seconds: 10);
                                        _player.seek(newPos > _duration ? _duration : newPos);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_speed != 1.0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5C518).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${_speed}x',
                                        style: const TextStyle(color: Color(0xFFF5C518), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ),

              // Live stream bottom bar with quick actions
              if (_showControls && widget.type == 'live' && !_hasError)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xBB000000), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _QuickAction(
                            icon: Icons.cast_connected,
                            label: 'Transmitir',
                            onTap: _openWithExternalPlayer,
                          ),
                          _QuickAction(
                            icon: Icons.share,
                            label: 'Compartir',
                            onTap: _shareStreamUrl,
                          ),
                          _QuickAction(
                            icon: Icons.refresh,
                            label: 'Reintentar',
                            onTap: () {
                              _retryCount = 0;
                              _retryPlayback();
                            },
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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.error_outline, color: Colors.red, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error al reproducir',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [Color(0xFFF5C518), Color(0xFFE5A000)]),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _retryCount = 0;
                                  setState(() {
                                    _hasError = false;
                                    _errorMessage = '';
                                    _isBuffering = true;
                                  });
                                  _retryPlayback();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: const Color(0xFF1A1D30),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('REINTENTAR'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF5C518).withOpacity(0.5)),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _openWithExternalPlayer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1D30),
                                  shadowColor: Colors.transparent,
                                  foregroundColor: const Color(0xFFF5C518),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.play_circle_outline, size: 18),
                                label: const Text('EXTERNO'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('VOLVER'),
                            ),
                          ],
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFF5C518), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom track shape that allows full-width slider
class CustomTrackShape extends RoundedRectSliderTrackShape {
  const CustomTrackShape();
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
