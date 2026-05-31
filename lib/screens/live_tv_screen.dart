import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/iptv_provider.dart';
import '../widgets/category_filter.dart';
import 'player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
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
                  hintText: 'Buscar canales...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                autofocus: true,
                onChanged: (v) => provider.setSearchQuery(v),
              )
            : Row(
                children: [
                  const Text('TV en Vivo'),
                  const SizedBox(width: 8),
                  if (provider.filteredLiveChannels.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00d4ff).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.filteredLiveChannels.length}',
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
          // Category filter
          CategoryFilter(
            categories: provider.liveCategories,
            selectedCategoryId: provider.selectedLiveCategory,
            onCategorySelected: (id) => provider.selectLiveCategory(id),
          ),

          // Channel list
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitThreeBounce(color: Color(0xFF00d4ff), size: 24),
                        SizedBox(height: 16),
                        Text('Cargando canales...', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : provider.filteredLiveChannels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tv_off, size: 64, color: Colors.grey.shade600),
                            const SizedBox(height: 16),
                            const Text(
                              'No se encontraron canales',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.liveCategories.length} categorias disponibles',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.selectLiveCategory(provider.selectedLiveCategory),
                        color: const Color(0xFF00d4ff),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: provider.filteredLiveChannels.length,
                          itemBuilder: (context, index) {
                            final channel = provider.filteredLiveChannels[index];
                            return _ChannelCard(
                              channel: channel,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                      title: channel.name,
                                      url: channel.streamUrl,
                                      type: 'live',
                                    ),
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

class _ChannelCard extends StatelessWidget {
  final dynamic channel;
  final VoidCallback onTap;

  const _ChannelCard({required this.channel, required this.onTap});

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: channel.logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: channel.logo,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Icon(Icons.tv, color: Color(0xFF00d4ff), size: 36),
                        errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Color(0xFF00d4ff), size: 36),
                      )
                    : const Icon(Icons.tv, color: Color(0xFF00d4ff), size: 36),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  channel.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00d4ff), Color(0xFF0099cc)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'EN VIVO',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
