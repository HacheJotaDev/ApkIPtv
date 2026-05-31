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
            expandedHeight: 300,
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
                            color: const Color(0xFF1A1D30),
                            child: const Icon(Icons.tv, size: 64, color: Color(0xFF00BCD4)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1A1D30),
                          child: const Icon(Icons.tv, size: 64, color: Color(0xFF00BCD4)),
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
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF121421), Color(0xFF0C0E1A)],
                ),
              ),
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
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (widget.series.rating.isNotEmpty)
                          _InfoChip(icon: Icons.star, label: widget.series.rating, color: const Color(0xFF00BCD4)),
                        if (widget.series.releaseDate.isNotEmpty)
                          _InfoChip(icon: Icons.calendar_today, label: widget.series.releaseDate, color: const Color(0xFF00BCD4)),
                        if (widget.series.genre.isNotEmpty)
                          _InfoChip(icon: Icons.category, label: widget.series.genre, color: Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.series.description.isNotEmpty) ...[
                      const Text('Sinopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2D4A).withOpacity(0.5)),
                        ),
                        child: Text(
                          widget.series.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Episodes section
                    if (_isLoading)
                      const Center(child: SpinKitThreeBounce(color: Color(0xFF00BCD4), size: 24))
                    else if (_seriesInfo != null && _seriesInfo!.seasons.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('Temporadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_seriesInfo!.seasons.length}',
                              style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
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
                                selectedColor: const Color(0xFF00BCD4),
                                backgroundColor: const Color(0xFF1A1D30),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF2A2D4A),
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFF1A1D30) : Colors.white,
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
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D30),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.tv_off, color: Colors.grey, size: 30),
                            ),
                            const SizedBox(height: 12),
                            const Text('No hay episodios disponibles', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => PlayerScreen(
                title: episode.name.isNotEmpty ? episode.name : 'T${episode.seasonNum}E${episode.episodeNum}',
                url: episode.streamUrl,
                type: 'series',
              ),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2D4A).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF0097A7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_circle, color: Color(0xFF1A1D30), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.name.isNotEmpty ? episode.name : 'Episodio ${episode.episodeNum}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'T${episode.seasonNum} E${episode.episodeNum}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow, color: Color(0xFF00BCD4)),
            ],
          ),
        ),
      ),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
