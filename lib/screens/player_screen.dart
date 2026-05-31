import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/iptv_models.dart';
import '../models/app_state.dart';

class PlayerScreen extends StatefulWidget {
  final Channel? channel;
  final VodItem? vodItem;
  final Episode? episode;

  const PlayerScreen({super.key, this.channel, this.vodItem, this.episode});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isBuffering = true;

  String get _title => widget.episode?.title ?? widget.channel?.name ?? widget.vodItem?.name ?? 'Reproductor';
  String get _streamUrl => widget.episode?.url ?? widget.channel?.url ?? widget.vodItem?.url ?? '';
  String get _subtitle => widget.channel?.group ?? (widget.vodItem?.type == 'series' ? 'Serie' : 'Pelicula') ?? '';

  @override
  void initState() {
    super.initState();
    
    _player = Player();
    _controller = VideoController(_player);
    
    WakelockPlus.enable();
    
    _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          _isBuffering = false;
        });
      }
    });

    _player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() {
          _isBuffering = buffering;
        });
      }
    });

    _player.stream.error.listen((error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = error;
          _isBuffering = false;
        });
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed && mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    _openStream();
    _startAutoHideTimer();
  }

  void _openStream() {
    if (_streamUrl.isEmpty) return;
    
    setState(() {
      _hasError = false;
      _isBuffering = true;
    });
    
    _player.open(Media(_streamUrl));
  }

  @override
  void dispose() {
    _player.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startAutoHideTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startAutoHideTimer();
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> _openExternalPlayer() async {
    final uri = Uri.tryParse(_streamUrl);
    if (uri != null) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el reproductor externo'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video area
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTap: _toggleFullscreen,
            child: Container(
              color: Colors.black,
              child: _buildVideoArea(),
            ),
          ),

          // Controls overlay
          if (_showControls)
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const Spacer(),
                    _buildCenterControls(),
                    const Spacer(),
                    _buildBottomControls(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE50914), size: 64),
            const SizedBox(height: 16),
            const Text('Error al reproducir', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage, style: TextStyle(color: Colors.grey[400], fontSize: 13), textAlign: TextAlign.center, maxLines: 2),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: _openStream, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _openExternalPlayer, icon: const Icon(Icons.open_in_new), label: const Text('Abrir externamente'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white)),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Video player
        Video(
          controller: _controller,
          fit: BoxFit.contain,
        ),
        // Buffering indicator
        if (_isBuffering)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE50914), strokeWidth: 3),
                  SizedBox(height: 16),
                  Text('Cargando...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (_subtitle.isNotEmpty) Text(_subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (widget.channel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fiber_manual_record, color: Colors.white, size: 8), SizedBox(width: 4), Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
              ),
            IconButton(icon: const Icon(Icons.open_in_new, color: Colors.white), onPressed: _openExternalPlayer),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 24), onPressed: () => _player.seek(Duration(milliseconds: _player.state.position.inMilliseconds - 10000))),
        ),
        const SizedBox(width: 24),
        // Play/Pause
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Forward 10s
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 24), onPressed: () => _player.seek(Duration(milliseconds: _player.state.position.inMilliseconds + 10000))),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final position = _player.state.position;
    final duration = _player.state.duration;
    final isLive = widget.channel != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar (not for live)
            if (!isLive && duration.inMilliseconds > 0)
              Column(
                children: [
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFE50914),
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 24), onPressed: _togglePlayPause),
                if (!isLive) Text(_formatDuration(position), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white, size: 22), onPressed: _openStream, tooltip: 'Recargar'),
                IconButton(icon: const Icon(Icons.open_in_new, color: Colors.white, size: 22), onPressed: _openExternalPlayer, tooltip: 'Reproductor externo'),
                IconButton(icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white, size: 28), onPressed: _toggleFullscreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
