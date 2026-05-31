import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/iptv_provider.dart';
import '../widgets/category_filter.dart';
import 'movie_detail_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IptvProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Buscar peliculas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                autofocus: true,
                onChanged: (v) => provider.setSearchQuery(v),
              )
            : Row(
                children: [
                  const Text('Peliculas'),
                  const SizedBox(width: 8),
                  if (provider.filteredVodMovies.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00d4ff).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.filteredVodMovies.length}',
                        style: const TextStyle(color: Color(0xFF00d4ff), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                provider.setSearchQuery('');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CategoryFilter(
            categories: provider.vodCategories,
            selectedCategoryId: provider.selectedVodCategory,
            onCategorySelected: (id) => provider.selectVodCategory(id),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitThreeBounce(color: Color(0xFF00d4ff), size: 24),
                        SizedBox(height: 16),
                        Text('Cargando peliculas...', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : provider.filteredVodMovies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.movie_outlined, size: 64, color: Colors.grey.shade600),
                            const SizedBox(height: 16),
                            const Text('No se encontraron peliculas', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('${provider.vodCategories.length} categorias disponibles',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.selectVodCategory(provider.selectedVodCategory),
                        color: const Color(0xFF00d4ff),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: provider.filteredVodMovies.length,
                          itemBuilder: (context, index) {
                            final movie = provider.filteredVodMovies[index];
                            return _MovieCard(
                              movie: movie,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MovieDetailScreen(movie: movie),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final dynamic movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1a2a4e), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              movie.logo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: movie.logo,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF0f1a2e),
                        child: const Icon(Icons.movie, color: Color(0xFF00d4ff), size: 36),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF0f1a2e),
                        child: const Icon(Icons.movie, color: Color(0xFF00d4ff), size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF0f1a2e),
                      child: const Icon(Icons.movie, color: Color(0xFF00d4ff), size: 36),
                    ),
              // Gradient overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (movie.rating.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              movie.rating,
                              style: const TextStyle(color: Colors.amber, fontSize: 10),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              // Play icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00d4ff).withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00d4ff).withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
