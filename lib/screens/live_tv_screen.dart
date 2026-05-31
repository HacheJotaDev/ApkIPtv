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
  bool _isGridView = true;

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
                        color: const Color(0xFF00BCD4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.filteredLiveChannels.length}',
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Vista lista' : 'Vista cuadricula',
          ),
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
            categories: provider.liveCategories,
            selectedCategoryId: provider.selectedLiveCategory,
            onCategorySelected: (id) => provider.selectLiveCategory(id),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitThreeBounce(color: Color(0xFF00BCD4), size: 24),
                        SizedBox(height: 16),
                        Text('Cargando canales...', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : provider.filteredLiveChannels.isEmpty
                    ? _EmptyState(
                        icon: Icons.tv_off,
                        title: 'No se encontraron canales',
                        subtitle: '${provider.liveCategories.length} categorias disponibles',
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.selectLiveCategory(provider.selectedLiveCategory),
                        color: const Color(0xFF00BCD4),
                        child: _isGridView
                            ? _buildGridView(provider)
                            : _buildListView(provider),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(IptvProvider provider) {
    return GridView.builder(
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
        return _ChannelGridCard(
          channel: channel,
          onTap: () => _openPlayer(context, channel.name, channel.streamUrl),
        );
      },
    );
  }

  Widget _buildListView(IptvProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.filteredLiveChannels.length,
      itemBuilder: (context, index) {
        final channel = provider.filteredLiveChannels[index];
        return _ChannelListTile(
          channel: channel,
          index: index,
          onTap: () => _openPlayer(context, channel.name, channel.streamUrl),
        );
      },
    );
  }

  void _openPlayer(BuildContext context, String title, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlayerScreen(title: title, url: url, type: 'live'),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _ChannelGridCard extends StatelessWidget {
  final dynamic channel;
  final VoidCallback onTap;

  const _ChannelGridCard({required this.channel, required this.onTap});

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
                        placeholder: (_, __) => const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 36),
                        errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 36),
                      )
                    : const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 36),
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
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'EN VIVO',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF1A1D30), fontSize: 9, fontWeight: FontWeight.bold),
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

class _ChannelListTile extends StatelessWidget {
  final dynamic channel;
  final int index;
  final VoidCallback onTap;

  const _ChannelListTile({required this.channel, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2A2D4A).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Channel number
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Color(0xFF1A1D30), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2038),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: channel.logo.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: channel.logo,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 22),
                          errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 22),
                        ),
                      )
                    : const Icon(Icons.tv, color: Color(0xFF00BCD4), size: 22),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (channel.categoryId.isNotEmpty)
                      Text(
                        channel.categoryId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                  ],
                ),
              ),
              // Live badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.play_circle_fill, color: Color(0xFF00BCD4), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            child: Icon(icon, size: 40, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
