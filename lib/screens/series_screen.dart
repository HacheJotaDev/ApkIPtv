import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/iptv_provider.dart';
import '../widgets/category_filter.dart';
import 'series_detail_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
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
                  hintText: 'Buscar series...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (v) => provider.setSearchQuery(v),
              )
            : Text('Series (${provider.filteredSeriesList.length})'),
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
            categories: provider.seriesCategories,
            selectedCategoryId: provider.selectedSeriesCategory,
            onCategorySelected: (id) => provider.selectSeriesCategory(id),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: SpinKitThreeBounce(color: Color(0xFF00d4ff), size: 24))
                : provider.filteredSeriesList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.tv_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No se encontraron series', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('${provider.seriesCategories.length} categorías disponibles',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.selectSeriesCategory(provider.selectedSeriesCategory),
                        color: const Color(0xFF00d4ff),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: provider.filteredSeriesList.length,
                          itemBuilder: (context, index) {
                            final series = provider.filteredSeriesList[index];
                            return _SeriesCard(
                              series: series,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SeriesDetailScreen(series: series),
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

class _SeriesCard extends StatelessWidget {
  final dynamic series;
  final VoidCallback onTap;

  const _SeriesCard({required this.series, required this.onTap});

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
              series.logo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: series.logo,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF16213e),
                        child: const Icon(Icons.tv, color: Color(0xFF00d4ff), size: 36),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF16213e),
                        child: const Icon(Icons.tv, color: Color(0xFF00d4ff), size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF16213e),
                      child: const Icon(Icons.tv, color: Color(0xFF00d4ff), size: 36),
                    ),
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
                        series.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (series.rating.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(series.rating, style: const TextStyle(color: Colors.amber, fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
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
