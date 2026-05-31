import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_state.dart';
import '../models/iptv_models.dart';
import 'player_screen.dart';

class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({super.key});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('TV en Vivo (${appState.filteredChannels.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: appState.channels.isEmpty
          ? _buildEmpty(context)
          : Column(
              children: [
                // Group filter chips
                if (appState.channelGroups.length > 1)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.5)),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: appState.channelGroups.length,
                      itemBuilder: (context, index) {
                        final group = appState.channelGroups[index];
                        final isSelected = group == appState.selectedChannelGroup;
                        final count = group == 'Todos' 
                            ? appState.channels.length 
                            : appState.channels.where((c) => c.group == group).length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(
                              '$group ($count)',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFE50914),
                            backgroundColor: const Color(0xFF2A2A4A),
                            checkmarkColor: Colors.white,
                            onSelected: (_) => appState.setSelectedChannelGroup(group),
                          ),
                        );
                      },
                    ),
                  ),
                // Channel list
                Expanded(
                  child: appState.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: appState.filteredChannels.length,
                          itemBuilder: (context, index) {
                            final channel = appState.filteredChannels[index];
                            return _ChannelTile(
                              channel: channel,
                              onTap: () => _openPlayer(context, channel),
                              onFavorite: () => appState.toggleFavoriteChannel(channel.id),
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
          Icon(Icons.live_tv, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No hay canales disponibles', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Conecta un servicio IPTV primero', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    showSearch(context: context, delegate: _LiveSearchDelegate(appState));
  }

  void _openPlayer(BuildContext context, Channel channel) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel)));
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _ChannelTile({required this.channel, required this.onTap, required this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF2A2A4A)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: channel.logo != null && channel.logo!.isNotEmpty
                ? CachedNetworkImage(imageUrl: channel.logo!, fit: BoxFit.contain, placeholder: (_, __) => const Center(child: Icon(Icons.live_tv, color: Color(0xFFE50914))), errorWidget: (_, __, ___) => const Center(child: Icon(Icons.live_tv, color: Color(0xFFE50914))))
                : const Center(child: Icon(Icons.live_tv, color: Color(0xFFE50914))),
          ),
        ),
        title: Text(channel.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(channel.group ?? 'Sin categoria', style: TextStyle(color: Colors.grey[400], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
              child: const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(channel.isFavorite ? Icons.favorite : Icons.favorite_border, color: channel.isFavorite ? const Color(0xFFE50914) : Colors.grey, size: 20),
              onPressed: onFavorite,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _LiveSearchDelegate extends SearchDelegate {
  final AppState appState;

  _LiveSearchDelegate(this.appState);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A2E)));
  }

  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = appState.channels.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final ch = results[index];
        return ListTile(
          leading: const Icon(Icons.live_tv, color: Color(0xFFE50914)),
          title: Text(ch.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(ch.group ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch))),
        );
      },
    );
  }
}
