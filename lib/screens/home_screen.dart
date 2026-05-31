import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  final List<Widget> _screens = [
    const LiveTvScreen(),
    const MoviesScreen(),
    const SettingsScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv, label: 'TV en Vivo'),
    _NavItem(icon: Icons.movie_outlined, activeIcon: Icons.movie, label: 'Peliculas'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Ajustes'),
  ];

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );
    // Initial ripple for first tab
    _rippleController.forward();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _rippleController.forward(from: 0.0);
  }

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
          color: const Color(0xFF121421),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: const Color(0xFF2A2D4A).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;
                return _NavButton(
                  item: item,
                  isSelected: isSelected,
                  rippleAnimation: isSelected ? _rippleAnimation : null,
                  count: index == 0
                      ? provider.liveChannels.length
                      : index == 1
                          ? provider.vodMovies.length
                          : 0,
                  onTap: () => _onTabTapped(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final Animation<double>? rippleAnimation;
  final int count;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    this.rippleAnimation,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: const Color(0xFF00BCD4).withOpacity(0.3),
            highlightColor: const Color(0xFF00BCD4).withOpacity(0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00BCD4).withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          key: ValueKey(isSelected),
                          color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.shade500,
                          size: 24,
                        ),
                      ),
                      if (count > 0 && !isSelected)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(minWidth: 14),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF1A1D30), fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.shade500,
                      fontSize: isSelected ? 11 : 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    child: Text(item.label),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected && rippleAnimation != null)
                    _RippleIndicator(animation: rippleAnimation!),
                  if (!isSelected)
                    Container(
                      width: 0,
                      height: 3,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated indicator that shows a ripple/expansion effect
class _RippleIndicator extends AnimatedWidget {
  const _RippleIndicator({required Animation<double> animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final progress = animation.value;

    return Container(
      width: 20 * progress,
      height: 3,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4DD0E1), Color(0xFF0097A7)]),
        borderRadius: BorderRadius.circular(2),
        boxShadow: progress < 1.0
            ? [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.5 * (1 - progress)),
                  blurRadius: 8 * (1 - progress),
                  spreadRadius: 2 * (1 - progress),
                ),
              ]
            : null,
      ),
    );
  }
}
