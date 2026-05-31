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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar películas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (v) => provider.setSearchQuery(v),
              )
            : Text('Películas (${provider.filteredVodMovies.length})'),
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
                ? const Center(child: SpinKitThreeBounce(color: Color(0xFF00d4ff), size: 24))
                : provider.filteredVodMovies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No se encontraron películas', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('${provider.vodCategories.length} categorías disponibles',
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
                        color: const Color(0xFF16213e),
                        child: const Icon(Icons.movie, color: Color(0xFF00d4ff), size: 36),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF16213e),
                        child: const Icon(Icons.movie, color: Color(0xFF00d4ff), size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF16213e),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00d4ff).withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
