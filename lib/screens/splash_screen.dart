import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import 'main_navigator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    
    // Auto-reconnect and navigate
    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Auto-reconnect if credentials exist
    if (appState.hasConnection) {
      await appState.autoReconnect();
    }
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigator()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0D0D0D),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'HacheJota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'IPTV',
                  style: TextStyle(
                    color: Color(0xFFE50914),
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: const Color(0xFFE50914).withOpacity(0.7),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sin anuncios - Sin VIP - Todo libre',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
