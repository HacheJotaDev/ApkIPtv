import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../services/cast_service.dart';

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
  final CastService _castService = CastService();

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
  Timer? _keepAliveTimer;
  bool _isDisposed = false;
  bool _isCasting = false;
  StreamSubscription? _playingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _bufferingSub;
  VoidCallback? _castListener;

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

    WakelockPlus.enable();
    _setupListeners();
    _setupCastListener();
    _initPlayer();
    _startHideControlsTimer();

    // Keep-alive timer for live streams - prevents stream from timing out
    if (widget.type == 'live') {
      _keepAliveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (!_isDisposed && _isPlaying) {
          // Keep the player active by checking position
          debugPrint('Keep-alive tick for live stream: ${widget.title}');
        }
      });
    }
  }

  void _setupCastListener() {
    _castListener = () {
      if (mounted && !_isDisposed) {
        setState(() {
          _isCasting = _castService.isConnected;
        });
      }
    };
    _castService.addListener(_castListener!);
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
        // For live streams, auto-retry more aggressively
        if (_retryCount < _maxRetries && widget.type == 'live') {
          _retryCount++;
          debugPrint('Auto-retry attempt $_retryCount/$_maxRetries');
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: 3), () {
            if (mounted && !_isDisposed) _retryPlayback();
          });
        } else if (widget.type != 'live') {
          // For VOD, show error immediately after max retries
          setState(() {
            _hasError = true;
            _errorMessage = _getFriendlyError(error);
            _isBuffering = false;
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
      if (mounted && !_isDisposed) setState(() => _position = position);
    });

    _durationSub = _player.stream.duration.listen((duration) {
      if (mounted && !_isDisposed) setState(() => _duration = duration);
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
      return 'Formato no soportado. Intenta transmitir a TV.';
    }
    if (lower.contains('eof') || lower.contains('end of file')) {
      return 'El stream se ha cerrado inesperadamente.';
    }
    return 'Error al reproducir. Intenta reintentar o transmitir a TV.';
  }

  Future<void> _initPlayer() async {
    try {
      // Configure player for better live stream stability
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

      // For live streams: set specific properties for stability
      if (widget.type == 'live') {
        await _player.play();
      }

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

  // ===== CAST TO TV FUNCTIONALITY =====

  /// Show cast options - real Chromecast integration
  void _showCastDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121421),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.cast, color: Color(0xFFF5C518), size: 24),
                SizedBox(width: 10),
                Text(
                  'Transmitir a TV',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Conecta tu dispositivo a una TV con Chromecast o Android TV',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Cast status
            if (_castService.isConnected) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.cast_connected, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Conectado a TV', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('Tu contenido se esta reproduciendo en la TV', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ] else if (_castService.isConnecting) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C518).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF5C518).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 44, height: 44, child: CircularProgressIndicator(color: Color(0xFFF5C518), strokeWidth: 3)),
                    SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Conectando...', style: TextStyle(color: Color(0xFFF5C518), fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('Selecciona tu dispositivo en la notificacion del sistema', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Cast to TV option
            _CastOption(
              icon: Icons.cast,
              iconColor: const Color(0xFFF5C518),
              title: _castService.isConnected ? 'Transmitir a la TV conectada' : 'Conectar y Transmitir',
              subtitle: _castService.isConnected
                  ? 'Envia este contenido a tu TV ahora'
                  : 'Selecciona tu TV/Chromecast desde el sistema',
              onTap: () {
                Navigator.pop(context);
                _castToTv();
              },
            ),
            const SizedBox(height: 10),
            _CastOption(
              icon: Icons.share,
              iconColor: Colors.green,
              title: 'Compartir enlace',
              subtitle: 'Envia el enlace a otra app o dispositivo',
              onTap: () {
                Navigator.pop(context);
                Share.share(widget.url, subject: widget.title);
              },
            ),
            const SizedBox(height: 10),
            _CastOption(
              icon: Icons.copy,
              iconColor: Colors.cyan,
              title: 'Copiar enlace',
              subtitle: 'Copia la URL para pegarla en cualquier reproductor',
              onTap: () {
                Navigator.pop(context);
                _copyStreamUrl();
              },
            ),
            if (_castService.isConnected) ...[
              const SizedBox(height: 10),
              _CastOption(
                icon: Icons.stop_circle_outlined,
                iconColor: Colors.red,
                title: 'Desconectar de TV',
                subtitle: 'Detiene la reproduccion en la TV',
                onTap: () {
                  Navigator.pop(context);
                  _castService.endSession();
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Cast the current stream to TV via Google Cast
  Future<void> _castToTv() async {
    if (!Platform.isAndroid) {
      _showCastNotAvailable();
      return;
    }

    try {
      final available = await _castService.isAvailableOnDevice();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Google Cast no esta disponible en este dispositivo. Necesitas Google Play Services.')),
                ],
              ),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // If already connected, just load the media
      if (_castService.isConnected) {
        final success = await _castService.loadMedia(
          url: widget.url,
          title: widget.title,
          subtitle: widget.type == 'live' ? 'TV en Vivo' : 'IPTV',
          imageUrl: '',
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Reproduciendo en TV')),
                ],
              ),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Not connected - prompt user to connect via system cast dialog
        // The user needs to use the system MediaRouteButton to connect first
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.cast, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Toca el boton de Cast en la barra de notificaciones de Android para conectar tu TV, luego vuelve a intentarlo')),
                ],
              ),
              backgroundColor: const Color(0xFF1A1D30),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Cast error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Error al transmitir: ${e.message ?? "Error desconocido"}')),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showCastNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Google Cast solo esta disponible en Android')),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Copy stream URL to clipboard
  void _copyStreamUrl() {
    Clipboard.setData(ClipboardData(text: widget.url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Enlace copiado al portapapeles')),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareStreamUrl() {
    Share.share('${widget.title}\n${widget.url}');
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
    _keepAliveTimer?.cancel();
    _playingSub?.cancel();
    _errorSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _bufferingSub?.cancel();
    if (_castListener != null) {
      _castService.removeListener(_castListener!);
    }
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
              // Video player - hide when casting
              if (!_isCasting)
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Video(controller: _controller),
                  ),
                ),

              // Casting overlay
              if (_isCasting)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121421),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF5C518).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFF5C518), Color(0xFFE5A000)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.cast_connected, color: Color(0xFF1A1D30), size: 44),
                        ),
                        const SizedBox(height: 16),
                        const Text('Reproduciendo en TV', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.title, style: const TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFFF5C518), Color(0xFFE5A000)])),
                              child: ElevatedButton.icon(
                                onPressed: () { _castService.pause(); },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: const Color(0xFF1A1D30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                icon: const Icon(Icons.pause, size: 18), label: const Text('PAUSAR'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.5))),
                              child: ElevatedButton.icon(
                                onPressed: () { _castService.endSession(); },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1D30), shadowColor: Colors.transparent, foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                icon: const Icon(Icons.stop, size: 18), label: const Text('DETENER'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Buffering indicator
              if (_isBuffering && !_hasError && !_isCasting)
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
                          if (widget.type == 'live')
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
                          // Cast button - always visible
                          Container(
                            decoration: BoxDecoration(
                              color: _castService.isConnected
                                  ? const Color(0xFFF5C518).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: _castService.isConnected
                                  ? Border.all(color: const Color(0xFFF5C518).withOpacity(0.5))
                                  : null,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _castService.isConnected ? Icons.cast_connected : Icons.cast,
                                color: _castService.isConnected ? const Color(0xFFF5C518) : Colors.white,
                                size: 22,
                              ),
                              onPressed: _showCastDialog,
                              tooltip: 'Transmitir a TV',
                            ),
                          ),
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
                                  case 'cast': _showCastDialog(); break;
                                  case 'share': _shareStreamUrl(); break;
                                  case 'copy': _copyStreamUrl(); break;
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
                                const PopupMenuItem(value: 'cast', child: Row(children: [Icon(Icons.cast, color: Color(0xFFF5C518), size: 20), SizedBox(width: 12), Text('Transmitir a TV', style: TextStyle(color: Colors.white))])),
                                const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, color: Color(0xFFF5C518), size: 20), SizedBox(width: 12), Text('Compartir enlace', style: TextStyle(color: Colors.white))])),
                                const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, color: Color(0xFFF5C518), size: 20), SizedBox(width: 12), Text('Copiar enlace', style: TextStyle(color: Colors.white))])),
                                const PopupMenuItem(value: 'retry', child: Row(children: [Icon(Icons.refresh, color: Color(0xFFF5C518), size: 20), SizedBox(width: 12), Text('Reintentar', style: TextStyle(color: Colors.white))])),
                                if (widget.type != 'live') ...[
                                  const PopupMenuDivider(),
                                  PopupMenuItem(child: Row(children: [const Icon(Icons.speed, color: Color(0xFFF5C518), size: 20), const SizedBox(width: 12), Text('Velocidad: ${_speed}x', style: const TextStyle(color: Colors.white70))])),
                                  ...[('speed_05', '0.5x'), ('speed_075', '0.75x'), ('speed_1', '1.0x (Normal)'), ('speed_125', '1.25x'), ('speed_15', '1.5x'), ('speed_2', '2.0x')].map((e) => PopupMenuItem(
                                    value: e.$1,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 52),
                                      child: Text(e.$2, style: TextStyle(
                                        color: _speed == double.parse(e.$1.replaceAll('speed_', '').replaceAll('_', '.')) ? const Color(0xFFF5C518) : Colors.white70,
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
              if (!_hasError && !_isBuffering && !_isCasting && (_showControls || !_isPlaying))
                Center(
                  child: GestureDetector(
                    onTap: () => _player.playOrPause(),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFF5C518), Color(0xFFE5A000)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFFF5C518).withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF1A1D30), size: 52),
                    ),
                  ),
                ),

              // Bottom controls for VOD
              if (_showControls && widget.type != 'live' && _duration > Duration.zero)
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
                              overlayColor: const Color(0xFFF5C518).withOpacity(0.2),
                              activeTrackColor: const Color(0xFFF5C518),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFFF5C518),
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
                                  if (_speed != 1.0) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF5C518).withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text('${_speed}x', style: const TextStyle(color: Color(0xFFF5C518), fontSize: 10, fontWeight: FontWeight.bold))),
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

              // Live stream bottom bar
              if (_showControls && widget.type == 'live' && !_hasError)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xBB000000), Colors.transparent]),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _QuickAction(icon: _castService.isConnected ? Icons.cast_connected : Icons.cast, label: _castService.isConnected ? 'En TV' : 'Transmitir', onTap: _showCastDialog, highlight: _castService.isConnected),
                          _QuickAction(icon: Icons.share, label: 'Compartir', onTap: () => Share.share(widget.url, subject: widget.title)),
                          _QuickAction(icon: Icons.copy, label: 'Copiar URL', onTap: _copyStreamUrl),
                          _QuickAction(icon: Icons.refresh, label: 'Reintentar', onTap: () { _retryCount = 0; _retryPlayback(); }),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFFF5C518), Color(0xFFE5A000)])),
                              child: ElevatedButton.icon(
                                onPressed: () { _retryCount = 0; setState(() { _hasError = false; _errorMessage = ''; _isBuffering = true; }); _retryPlayback(); },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: const Color(0xFF1A1D30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                icon: const Icon(Icons.refresh, size: 18), label: const Text('REINTENTAR'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF5C518).withOpacity(0.5))),
                              child: ElevatedButton.icon(
                                onPressed: _showCastDialog,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1D30), shadowColor: Colors.transparent, foregroundColor: const Color(0xFFF5C518), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                icon: const Icon(Icons.cast, size: 18), label: const Text('EN TV'),
                              ),
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
  final bool highlight;

  const _QuickAction({required this.icon, required this.label, required this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFF5C518).withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: highlight ? Border.all(color: const Color(0xFFF5C518).withOpacity(0.4)) : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: highlight ? const Color(0xFFF5C518) : const Color(0xFFF5C518), size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: highlight ? const Color(0xFFF5C518) : Colors.white70, fontSize: 10, fontWeight: highlight ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _CastOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CastOption({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF1A1D30), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2D4A).withOpacity(0.5))),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)])),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
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
