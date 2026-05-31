import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/series.dart';
import '../providers/iptv_provider.dart';
import 'player_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  SeriesInfo? _seriesInfo;
  bool _isLoading = true;
  int _selectedSeason = 1;

  @override
  void initState() {
    super.initState();
    _loadSeriesInfo();
  }

  Future<void> _loadSeriesInfo() async {
    final provider = Provider.of<IptvProvider>(context, listen: false);
    final info = await provider.getSeriesInfo(widget.series.id);
    if (mounted) {
      setState(() {
        _seriesInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.series.logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.series.logo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF1a1a2e),
                            child: const Icon(Icons.tv, size: 64, color: Color(0xFF00d4ff)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1a1a2e),
                          child: const Icon(Icons.tv, size: 64, color: Color(0xFF00d4ff)),
                        ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.series.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (widget.series.rating.isNotEmpty)
                        _InfoChip(icon: Icons.star, label: widget.series.rating, color: Colors.amber),
                      if (widget.series.releaseDate.isNotEmpty)
                        _InfoChip(icon: Icons.calendar_today, label: widget.series.releaseDate, color: Colors.blue),
                      if (widget.series.genre.isNotEmpty)
                        _InfoChip(icon: Icons.category, label: widget.series.genre, color: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.series.description.isNotEmpty) ...[
                    const Text('Sinopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(widget.series.description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                  ],
                  const SizedBox(height: 24),

                  // Episodes
                  if (_isLoading)
                    const Center(child: SpinKitThreeBounce(color: Color(0xFF00d4ff), size: 24))
                  else if (_seriesInfo != null && _seriesInfo!.seasons.isNotEmpty) ...[
                    const Text('Temporadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    // Season selector
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _seriesInfo!.seasons.keys.length,
                        itemBuilder: (context, index) {
                          final seasonNum = _seriesInfo!.seasons.keys.elementAt(index);
                          final isSelected = seasonNum == _selectedSeason.toString();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('T$seasonNum'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedSeason = int.parse(seasonNum)),
                              selectedColor: const Color(0xFF00d4ff),
                              backgroundColor: const Color(0xFF16213e),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Episodes list
                    ...(_seriesInfo!.seasons[_selectedSeason.toString()] ?? [])
                        .map((episode) => _EpisodeTile(episode: episode)),
                  ] else ...[
                    const Center(
                      child: Text('No hay episodios disponibles', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final SeriesEpisode episode;

  const _EpisodeTile({required this.episode});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.play_circle, color: Color(0xFF00d4ff)),
      ),
      title: Text(
        episode.name.isNotEmpty ? episode.name : 'Episodio ${episode.episodeNum}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'T${episode.seasonNum} E${episode.episodeNum}',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              title: episode.name.isNotEmpty ? episode.name : 'T${episode.seasonNum}E${episode.episodeNum}',
              url: episode.streamUrl,
              type: 'series',
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
