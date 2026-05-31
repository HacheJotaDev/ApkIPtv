import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'models/app_state.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(prefs);
  
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const HacheJotaIPTV(),
    ),
  );
}

class HacheJotaIPTV extends StatelessWidget {
  const HacheJotaIPTV({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HacheJota IPTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE50914),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          secondary: Color(0xFFE50914),
          surface: Color(0xFF1A1A2E),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: Color(0xFFE50914),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A4A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIconColor: Colors.grey,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
