import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_state.dart';
import '../models/iptv_models.dart';
import 'player_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Peliculas (${appState.filteredMovies.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(context)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {},
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'az', child: Text('A - Z')),
              const PopupMenuItem(value: 'za', child: Text('Z - A')),
              const PopupMenuItem(value: 'new', child: Text('Mas recientes')),
              const PopupMenuItem(value: 'rating', child: Text('Mejor valoradas')),
            ],
          ),
        ],
      ),
      body: appState.movies.isEmpty
          ? _buildEmpty(context)
          : Column(
              children: [
                // Category filter
                if (appState.movieGroups.length > 1)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.5)),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: appState.movieGroups.length,
                      itemBuilder: (context, index) {
                        final group = appState.movieGroups[index];
                        final isSelected = group == appState.selectedMovieGroup;
                        final count = group == 'Todos' 
                            ? appState.movies.length 
                            : appState.movies.where((v) => v.group == group).length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text('$group ($count)', style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 11)),
                            selected: isSelected,
                            selectedColor: const Color(0xFFE50914),
                            backgroundColor: const Color(0xFF2A2A4A),
                            checkmarkColor: Colors.white,
                            onSelected: (_) => appState.setSelectedMovieGroup(group),
                          ),
                        );
                      },
                    ),
                  ),
                // Grid of movies
                Expanded(
                  child: appState.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: appState.filteredMovies.length,
                          itemBuilder: (context, index) {
                            final vod = appState.filteredMovies[index];
                            return _VodGridCard(
                              vod: vod,
                              onTap: () => _openDetail(context, vod),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No hay peliculas disponibles', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Conecta un servicio IPTV primero', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    showSearch(context: context, delegate: _VodSearchDelegate(appState, 'movie'));
  }

  void _openDetail(BuildContext context, VodItem vod) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _VodDetailScreen(vod: vod)));
  }
}

class _VodGridCard extends StatelessWidget {
  final VodItem vod;
  final VoidCallback onTap;

  const _VodGridCard({required this.vod, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF1A1A2E), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              vod.poster != null && vod.poster!.isNotEmpty
                  ? CachedNetworkImage(imageUrl: vod.poster!, fit: BoxFit.cover, placeholder: (_, __) => Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 36))), errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 36))))
                  : Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 36))),
              if (vod.rating != null && vod.rating!.isNotEmpty)
                Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.amber, size: 10), const SizedBox(width: 2), Text(vod.rating!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))]))),
              Positioned(left: 0, right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(vod.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis), if (vod.year != null) Text(vod.year!, style: TextStyle(color: Colors.grey[400], fontSize: 9))]))),
            ],
          ),
        ),
      ),
    );
  }
}

class _VodDetailScreen extends StatelessWidget {
  final VodItem vod;

  const _VodDetailScreen({required this.vod});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
                  vod.poster != null && vod.poster!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: vod.poster!, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1A1A2E), child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 64))),
                  Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xFF0D0D0D)]))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vod.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (vod.year != null) _InfoChip(icon: Icons.calendar_today, text: vod.year!),
                      if (vod.rating != null) ...[const SizedBox(width: 8), _InfoChip(icon: Icons.star, text: vod.rating!)],
                      if (vod.duration != null) ...[const SizedBox(width: 8), _InfoChip(icon: Icons.access_time, text: vod.duration!)],
                      const SizedBox(width: 8),
                      const _InfoChip(icon: Icons.movie, text: 'Pelicula'),
                    ],
                  ),
                  if (vod.group != null) ...[
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(8)), child: Text(vod.group!, style: TextStyle(color: Colors.grey[300], fontSize: 13))),
                  ],
                  if (vod.plot != null && vod.plot!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Sinopsis', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(vod.plot!, style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(vodItem: vod))), icon: const Icon(Icons.play_arrow), label: const Text('Reproducir'))),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: () => appState.toggleFavoriteVod(vod.id), icon: Icon(vod.isFavorite ? Icons.favorite : Icons.favorite_border), label: Text(vod.isFavorite ? 'Quitar de Favoritos' : 'Agregar a Favoritos'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE50914), side: const BorderSide(color: Color(0xFFE50914)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
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
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFFE50914), size: 14), const SizedBox(width: 4), Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 13))]);
  }
}

class _VodSearchDelegate extends SearchDelegate {
  final AppState appState;
  final String type;

  _VodSearchDelegate(this.appState, this.type);

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A2E)));

  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase();
    final items = appState.movies.where((v) => v.name.toLowerCase().contains(q)).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.6, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final vod = items[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _VodDetailScreen(vod: vod))),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF1A1A2E)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  vod.poster != null && vod.poster!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: vod.poster!, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.movie, color: Colors.grey))),
                  Positioned(left: 0, right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])), child: Text(vod.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
