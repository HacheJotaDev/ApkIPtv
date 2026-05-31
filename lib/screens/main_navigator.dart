import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import 'home_screen.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'series_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LiveTVScreen(),
    const MoviesScreen(),
    const SeriesScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Listen for status message changes to show snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.statusMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appState.statusMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status bar at bottom
          if (appState.isConnected && appState.statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFF1B5E20),
              child: Text(
                appState.statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.live_tv_outlined),
                activeIcon: Icon(Icons.live_tv),
                label: 'TV en Vivo',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.movie_outlined),
                activeIcon: Icon(Icons.movie),
                label: 'Peliculas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tv_outlined),
                activeIcon: Icon(Icons.tv),
                label: 'Series',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Favoritos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
