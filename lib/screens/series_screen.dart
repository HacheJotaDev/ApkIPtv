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
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Buscar series...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                autofocus: true,
                onChanged: (v) => provider.setSearchQuery(v),
              )
            : Row(
                children: [
                  const Text('Series'),
                  const SizedBox(width: 8),
                  if (provider.filteredSeriesList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.filteredSeriesList.length}',
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.bold),
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
            categories: provider.seriesCategories,
            selectedCategoryId: provider.selectedSeriesCategory,
            onCategorySelected: (id) => provider.selectSeriesCategory(id),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitThreeBounce(color: Color(0xFF00BCD4), size: 24),
                        SizedBox(height: 16),
                        Text('Cargando series...', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : provider.filteredSeriesList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D30),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF2A2D4A).withOpacity(0.5)),
                              ),
                              child: Icon(Icons.tv_outlined, size: 40, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            const Text('No se encontraron series', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('${provider.seriesCategories.length} categorias disponibles',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.selectSeriesCategory(provider.selectedSeriesCategory),
                        color: const Color(0xFF00BCD4),
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
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => SeriesDetailScreen(series: series),
                                    transitionDuration: const Duration(milliseconds: 300),
                                    transitionsBuilder: (_, animation, __, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF2A2D4A).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              series.logo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: series.logo,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF131630),
                        child: const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 36),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF131630),
                        child: const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF131630),
                      child: const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 36),
                    ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        series.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (series.rating.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFF00BCD4), size: 12),
                            const SizedBox(width: 2),
                            Text(series.rating, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF0097A7)]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, color: Color(0xFF1A1D30), size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
