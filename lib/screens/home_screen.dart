import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LiveTvScreen(),
    const MoviesScreen(),
    const SeriesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IptvProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF0f0f1e)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedItemColor: const Color(0xFF00d4ff),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: provider.liveChannels.isNotEmpty,
                label: Text('${provider.liveChannels.length}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.live_tv_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: provider.liveChannels.isNotEmpty,
                label: Text('${provider.liveChannels.length}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.live_tv),
              ),
              label: 'TV en Vivo',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: provider.vodMovies.isNotEmpty,
                label: Text('${provider.vodMovies.length}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.movie_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: provider.vodMovies.isNotEmpty,
                label: Text('${provider.vodMovies.length}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.movie),
              ),
              label: 'Peliculas',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: provider.seriesList.isNotEmpty,
                label: Text('${provider.seriesList.length}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.tv_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: provider.seriesList.isNotEmpty,
                label: Text('${provider.seriesList.length}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.tv),
              ),
              label: 'Series',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
