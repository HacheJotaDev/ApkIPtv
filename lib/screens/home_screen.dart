import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_state.dart';
import '../models/iptv_models.dart';
import 'player_screen.dart';
import 'connection_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text('HacheJota IPTV'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(context)),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Conectar',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectionSetupScreen())),
          ),
        ],
      ),
      body: !appState.hasConnection
          ? _buildNoConnection(context)
          : RefreshIndicator(
              color: const Color(0xFFE50914),
              onRefresh: () => appState.autoReconnect(),
              child: CustomScrollView(
                slivers: [
                  if (appState.isLoading && appState.channels.isEmpty)
                    const SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Color(0xFFE50914)), SizedBox(height: 16), Text('Cargando contenido...', style: TextStyle(color: Colors.grey))]))),
                  
                  if (appState.channels.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _SectionHeader(title: 'Canales en Vivo', icon: Icons.live_tv, count: appState.channels.length, onSeeAll: () => _navigateToTab(context, 1))),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: appState.channels.length > 20 ? 20 : appState.channels.length,
                          itemBuilder: (context, index) => _ChannelCard(channel: appState.channels[index], onTap: () => _openPlayer(context, channel: appState.channels[index])),
                        ),
                      ),
                    ),
                  ],
                  if (appState.movies.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _SectionHeader(title: 'Peliculas', icon: Icons.movie, count: appState.movies.length, onSeeAll: () => _navigateToTab(context, 2))),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _VodCard(vod: appState.movies[index], onTap: () => _openPlayer(context, vodItem: appState.movies[index])),
                          childCount: appState.movies.length > 9 ? 9 : appState.movies.length,
                        ),
                      ),
                    ),
                  ],
                  if (appState.series.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _SectionHeader(title: 'Series', icon: Icons.tv, count: appState.series.length, onSeeAll: () => _navigateToTab(context, 3))),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _VodCard(vod: appState.series[index], onTap: () => _openSeriesDetail(context, appState.series[index])),
                          childCount: appState.series.length > 9 ? 9 : appState.series.length,
                        ),
                      ),
                    ),
                  ],
                  if (appState.channels.isEmpty && appState.movies.isEmpty && appState.series.isEmpty && !appState.isLoading)
                    SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_download, size: 64, color: Colors.grey[600]), const SizedBox(height: 16), Text('Conectado pero sin datos', style: TextStyle(color: Colors.grey[400])), const SizedBox(height: 8), Text('Intenta conectar de nuevo o verifica tus credenciales', style: TextStyle(color: Colors.grey[500], fontSize: 13))]))),
                ],
              ),
            ),
    );
  }

  Widget _buildNoConnection(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 120, height: 120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF2A2A4A)])), child: const Icon(Icons.connected_tv, size: 56, color: Color(0xFFE50914))),
            const SizedBox(height: 24),
            const Text('Bienvenido a HacheJota IPTV', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Conecta tu servicio IPTV para empezar a ver canales, peliculas y series.', style: TextStyle(color: Colors.grey[400], fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectionSetupScreen())), icon: const Icon(Icons.add_circle_outline), label: const Text('Conectar Servicio IPTV'))),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    // This won't directly work since MainNavigator controls the tab,
    // but we can navigate using a callback or just pop and switch
  }

  void _showSearch(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    showSearch(context: context, delegate: _IptvSearchDelegate(appState));
  }

  void _openPlayer(BuildContext context, {Channel? channel, VodItem? vodItem}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel, vodItem: vodItem)));
  }

  void _openSeriesDetail(BuildContext context, VodItem series) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _SeriesQuickDetail(series: series)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, required this.icon, this.count, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), 
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE50914), size: 20), 
          const SizedBox(width: 8), 
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE50914).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('$count', style: const TextStyle(color: Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
          const Spacer(), 
          TextButton(onPressed: onSeeAll, child: const Text('Ver todo', style: TextStyle(color: Color(0xFFE50914))))
        ]
      )
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  const _ChannelCard({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        width: 110, 
        margin: const EdgeInsets.only(right: 12), 
        child: Column(
          children: [
            Container(
              width: 80, height: 80, 
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF2A2A4A)), 
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16), 
                child: (channel.logo != null && channel.logo!.isNotEmpty) 
                  ? CachedNetworkImage(imageUrl: channel.logo!, fit: BoxFit.contain, placeholder: (_, __) => const Center(child: Icon(Icons.live_tv, color: Color(0xFFE50914), size: 32)), errorWidget: (_, __, ___) => const Center(child: Icon(Icons.live_tv, color: Color(0xFFE50914), size: 32))) 
                  : const Center(child: Icon(Icons.live_tv, color: Color(0xFFE50914), size: 32))
              )
            ), 
            const SizedBox(height: 6), 
            Text(channel.name, style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)
          ]
        )
      )
    );
  }
}

class _VodCard extends StatelessWidget {
  final VodItem vod;
  final VoidCallback onTap;
  const _VodCard({required this.vod, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF1A1A2E)), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), 
          child: Stack(
            fit: StackFit.expand, 
            children: [
              (vod.poster != null && vod.poster!.isNotEmpty) 
                ? CachedNetworkImage(imageUrl: vod.poster!, fit: BoxFit.cover, placeholder: (_, __) => Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 40))), errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A4A), child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 40)))) 
                : Container(color: const Color(0xFF2A2A4A), child: Center(child: Icon(vod.type == 'series' ? Icons.tv : Icons.movie, color: Colors.grey, size: 40))),
              if (vod.type == 'series')
                Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(4)), child: const Text('SERIE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
              if (vod.rating != null && vod.rating!.isNotEmpty)
                Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.amber, size: 10), const SizedBox(width: 2), Text(vod.rating!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))]))),
              Positioned(left: 0, right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(vod.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis), if (vod.year != null) Text(vod.year!, style: TextStyle(color: Colors.grey[400], fontSize: 9))])))
            ]
          )
        )
      )
    );
  }
}

class _SeriesQuickDetail extends StatelessWidget {
  final VodItem series;
  const _SeriesQuickDetail({required this.series});

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
                  series.poster != null && series.poster!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: series.poster!, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1A1A2E), child: const Center(child: Icon(Icons.tv, color: Colors.grey, size: 64))),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xFF0D0D0D)]),
                    ),
                  ),
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
                  Text(series.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Para ver los episodios, ve a la seccion de Series en el menu principal.', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IptvSearchDelegate extends SearchDelegate {
  final AppState appState;
  _IptvSearchDelegate(this.appState);

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
    final channels = appState.channels.where((c) => c.name.toLowerCase().contains(q)).toList();
    final movies = appState.movies.where((v) => v.name.toLowerCase().contains(q)).toList();
    final seriesList = appState.series.where((v) => v.name.toLowerCase().contains(q)).toList();
    return ListView(children: [
      if (channels.isNotEmpty) ...[
        const Padding(padding: EdgeInsets.all(16), child: Text('Canales', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 16))),
        ...channels.map((ch) => ListTile(leading: const Icon(Icons.live_tv, color: Color(0xFFE50914)), title: Text(ch.name, style: const TextStyle(color: Colors.white)), subtitle: Text(ch.group ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch))))),
      ],
      if (movies.isNotEmpty) ...[
        const Padding(padding: EdgeInsets.all(16), child: Text('Peliculas', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 16))),
        ...movies.map((vod) => ListTile(leading: const Icon(Icons.movie, color: Color(0xFFE50914)), title: Text(vod.name, style: const TextStyle(color: Colors.white)), subtitle: Text(vod.group ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(vodItem: vod))))),
      ],
      if (seriesList.isNotEmpty) ...[
        const Padding(padding: EdgeInsets.all(16), child: Text('Series', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 16))),
        ...seriesList.map((s) => ListTile(leading: const Icon(Icons.tv, color: Color(0xFFE50914)), title: Text(s.name, style: const TextStyle(color: Colors.white)), subtitle: Text(s.group ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)))),
      ],
    ]);
  }
}
