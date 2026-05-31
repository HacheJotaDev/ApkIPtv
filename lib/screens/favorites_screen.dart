import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_state.dart';
import '../models/iptv_models.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final favChannels = appState.favoriteChannels;
    final favMovies = appState.favoriteMovies;
    final favSeries = appState.favoriteSeries;
    final totalFavorites = favChannels.length + favMovies.length + favSeries.length;

    return Scaffold(
      appBar: AppBar(title: Text('Favoritos ($totalFavorites)')),
      body: favChannels.isEmpty && favMovies.isEmpty && favSeries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('Sin favoritos aun', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Agrega canales, peliculas y series\na favoritos para verlos aqui', style: TextStyle(color: Colors.grey[500], fontSize: 14), textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (favChannels.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(children: [Icon(Icons.live_tv, color: Color(0xFFE50914), size: 20), SizedBox(width: 8), Text('Canales Favoritos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
                  ),
                  ...favChannels.map((channel) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF2A2A4A)), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: channel.logo != null && channel.logo!.isNotEmpty ? CachedNetworkImage(imageUrl: channel.logo!, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.live_tv, color: Color(0xFFE50914))) : const Icon(Icons.live_tv, color: Color(0xFFE50914)))),
                      title: Text(channel.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(channel.group ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      trailing: IconButton(icon: const Icon(Icons.favorite, color: Color(0xFFE50914)), onPressed: () => appState.toggleFavoriteChannel(channel.id)),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel))),
                    ),
                  )),
                ],
                if (favMovies.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(children: [Icon(Icons.movie, color: Color(0xFFE50914), size: 20), SizedBox(width: 8), Text('Peliculas Favoritas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
                  ),
                  ...favMovies.map((vod) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF2A2A4A)), child: vod.poster != null && vod.poster!.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: vod.poster!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.movie, color: Color(0xFFE50914)))) : const Icon(Icons.movie, color: Color(0xFFE50914))),
                      title: Text(vod.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text('${vod.group ?? ''} ${vod.year != null ? '- ${vod.year}' : ''}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      trailing: IconButton(icon: const Icon(Icons.favorite, color: Color(0xFFE50914)), onPressed: () => appState.toggleFavoriteVod(vod.id)),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(vodItem: vod))),
                    ),
                  )),
                ],
                if (favSeries.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(children: [Icon(Icons.tv, color: Color(0xFFE50914), size: 20), SizedBox(width: 8), Text('Series Favoritas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
                  ),
                  ...favSeries.map((s) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF2A2A4A)), child: s.poster != null && s.poster!.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: s.poster!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Color(0xFFE50914)))) : const Icon(Icons.tv, color: Color(0xFFE50914))),
                      title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.group ?? ''} ${s.year != null ? '- ${s.year}' : ''}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      trailing: IconButton(icon: const Icon(Icons.favorite, color: Color(0xFFE50914)), onPressed: () => appState.toggleFavoriteVod(s.id)),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(vodItem: s))),
                    ),
                  )),
                ],
              ],
            ),
    );
  }
}
