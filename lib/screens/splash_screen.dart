import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final provider = Provider.of<IptvProvider>(context, listen: false);
    final success = await provider.tryAutoLogin();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a0a),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00d4ff), Color(0xFF0099cc)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00d4ff).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'XTREAM IPTV',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sin VIP • Sin Anuncios',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF00d4ff),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),
              const SpinKitThreeBounce(
                color: Color(0xFF00d4ff),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
