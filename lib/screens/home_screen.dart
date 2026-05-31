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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: provider.liveChannels.isNotEmpty,
              label: Text('${provider.liveChannels.length}', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.live_tv),
            ),
            label: 'TV en Vivo',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: provider.vodMovies.isNotEmpty,
              label: Text('${provider.vodMovies.length}', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.movie),
            ),
            label: 'Películas',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: provider.seriesList.isNotEmpty,
              label: Text('${provider.seriesList.length}', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.tv),
            ),
            label: 'Series',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
