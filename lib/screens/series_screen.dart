import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_state.dart';
import '../models/iptv_models.dart';
import 'player_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Series (${appState.filteredSeries.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(context)),
        ],
      ),
      body: appState.series.isEmpty
          ? _buildEmpty(context)
          : Column(
              children: [
                // Category filter
                if (appState.seriesGroups.length > 1)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.5)),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: appState.seriesGroups.length,
                      itemBuilder: (context, index) {
                        final group = appState.seriesGroups[index];
                        final isSelected = group == appState.selectedSeriesGroup;
                        final count = group == 'Todos' 
                            ? appState.series.length 
                            : appState.series.where((v) => v.group == group).length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text('$group ($count)', style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 11)),
                            selected: isSelected,
                            selectedColor: const Color(0xFFE50914),
                            backgroundColor: const Color(0xFF2A2A4A),
                            checkmarkColor: Colors.white,
                            onSelected: (_) => appState.setSelectedSeriesGroup(group),
                          ),
                        );
                      },
                    ),
                  ),
                // Grid of series
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
                          itemCount: appState.filteredSeries.length,
                          itemBuilder: (context, index) {
                            final series = appState.filteredSeries[index];
                            return _SeriesGridCard(
                              series: series,
                              onTap: () => _openDetail(context, series),
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
          Icon(Icons.tv, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No hay series disponibles', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Conecta un servicio IPTV primero', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    showSearch(context: context, delegate: _SeriesSearchDelegate(appState));
  }

  void _openDetail(BuildContext context, VodItem series) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _SeriesDetailScreen(series: series)));
  }
}

class _SeriesGridCard extends StatelessWidget {
  final VodItem series;
  final VoidCallback onTap;

  const _SeriesGridCard({required this.series, required this.onTap});

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
              series.poster != null && series.poster!.isNotEmpty
                  ? CachedNetworkImage(imageUrl: series.poster!, fit: BoxFit.cover, placeholder: (_, __) => Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.tv, color: Colors.grey, size: 36))), errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.tv, color: Colors.grey, size: 36))))
                  : Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.tv, color: Colors.grey, size: 36))),
              Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(4)), child: const Text('SERIE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
              if (series.rating != null && series.rating!.isNotEmpty)
                Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.amber, size: 10), const SizedBox(width: 2), Text(series.rating!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))]))),
              Positioned(left: 0, right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(series.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis), if (series.year != null) Text(series.year!, style: TextStyle(color: Colors.grey[400], fontSize: 9))]))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeriesDetailScreen extends StatefulWidget {
  final VodItem series;

  const _SeriesDetailScreen({required this.series});

  @override
  State<_SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<_SeriesDetailScreen> {
  List<SeriesSeason> _seasons = [];
  bool _isLoadingSeasons = false;
  int _expandedSeason = 0;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.credentials == null) return;

    setState(() => _isLoadingSeasons = true);
    
    try {
      final seasons = await appState.service.fetchSeriesInfo(appState.credentials!, widget.series.id);
      if (mounted) {
        setState(() {
          _seasons = seasons;
          _isLoadingSeasons = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSeasons = false);
    }
  }

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
                  widget.series.poster != null && widget.series.poster!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: widget.series.poster!, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1A1A2E), child: const Center(child: Icon(Icons.tv, color: Colors.grey, size: 64))),
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
                  Text(widget.series.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.series.year != null) _InfoChip(icon: Icons.calendar_today, text: widget.series.year!),
                      if (widget.series.rating != null) ...[const SizedBox(width: 8), _InfoChip(icon: Icons.star, text: widget.series.rating!)],
                      const SizedBox(width: 8),
                      const _InfoChip(icon: Icons.tv, text: 'Serie'),
                    ],
                  ),
                  if (widget.series.group != null) ...[
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(8)), child: Text(widget.series.group!, style: TextStyle(color: Colors.grey[300], fontSize: 13))),
                  ],
                  if (widget.series.plot != null && widget.series.plot!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Sinopsis', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.series.plot!, style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5)),
                  ],
                  const SizedBox(height: 12),
                  // Favorite button
                  SizedBox(
                    width: double.infinity, height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => appState.toggleFavoriteVod(widget.series.id),
                      icon: Icon(widget.series.isFavorite ? Icons.favorite : Icons.favorite_border),
                      label: Text(widget.series.isFavorite ? 'Quitar de Favoritos' : 'Agregar a Favoritos'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE50914), side: const BorderSide(color: Color(0xFFE50914)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Seasons
                  if (_isLoadingSeasons)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFFE50914))))
                  else if (_seasons.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [Icon(Icons.tv, size: 48, color: Colors.grey[600]), const SizedBox(height: 12), Text('No se pudieron cargar los episodios', style: TextStyle(color: Colors.grey[400])), const SizedBox(height: 8), Text('Intenta reproducir directamente', style: TextStyle(color: Colors.grey[500], fontSize: 12)), const SizedBox(height: 16), ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(vodItem: widget.series))), icon: const Icon(Icons.play_arrow), label: const Text('Reproducir'))])))
                  else ...[
                    Text('Temporadas (${_seasons.length})', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...List.generate(_seasons.length, (i) {
                      final season = _seasons[i];
                      final isExpanded = _expandedSeason == i;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          initiallyExpanded: i == 0,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(season.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('${season.episodes.length} episodios', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          trailing: isExpanded 
                              ? const Icon(Icons.expand_less, color: Color(0xFFE50914)) 
                              : const Icon(Icons.expand_more, color: Colors.grey),
                          onExpansionChanged: (expanded) {
                            if (expanded) setState(() => _expandedSeason = i);
                          },
                          children: season.episodes.map((episode) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Text('${episode.episodeNum ?? '?'}', style: const TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 14))),
                            ),
                            title: Text(episode.title, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: episode.plot != null ? Text(episode.plot!, style: TextStyle(color: Colors.grey[500], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                            trailing: const Icon(Icons.play_circle_filled, color: Color(0xFFE50914)),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(vodItem: widget.series, episode: episode))),
                          )).toList(),
                        ),
                      );
                    }),
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
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFFE50914), size: 14), const SizedBox(width: 4), Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 13))]);
  }
}

class _SeriesSearchDelegate extends SearchDelegate {
  final AppState appState;

  _SeriesSearchDelegate(this.appState);

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
    final items = appState.series.where((v) => v.name.toLowerCase().contains(q)).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.6, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final s = items[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _SeriesDetailScreen(series: s))),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF1A1A2E)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  s.poster != null && s.poster!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: s.poster!, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.tv, color: Colors.grey))),
                  Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(4)), child: const Text('SERIE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
                  Positioned(left: 0, right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])), child: Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
