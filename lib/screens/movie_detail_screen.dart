import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/movie.dart';
import '../providers/iptv_provider.dart';
import 'player_screen.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

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
                  movie.logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.logo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF1a1a2e),
                            child: const Icon(Icons.movie, size: 64, color: Color(0xFF00d4ff)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1a1a2e),
                          child: const Icon(Icons.movie, size: 64, color: Color(0xFF00d4ff)),
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
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              title: movie.name,
                              url: movie.streamUrl,
                              type: 'movie',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00d4ff).withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
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
                    movie.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Info row
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (movie.rating.isNotEmpty)
                        _InfoChip(icon: Icons.star, label: movie.rating, color: Colors.amber),
                      if (movie.releaseDate.isNotEmpty)
                        _InfoChip(icon: Icons.calendar_today, label: movie.releaseDate, color: Colors.blue),
                      if (movie.duration.isNotEmpty)
                        _InfoChip(icon: Icons.schedule, label: movie.duration, color: Colors.green),
                      if (movie.genre.isNotEmpty)
                        _InfoChip(icon: Icons.category, label: movie.genre, color: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Play button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              title: movie.name,
                              url: movie.streamUrl,
                              type: 'movie',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('REPRODUCIR'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  if (movie.description.isNotEmpty) ...[
                    const Text(
                      'Sinopsis',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                  ],
                  if (movie.director.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Director: ${movie.director}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                  if (movie.cast.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Reparto: ${movie.cast}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
