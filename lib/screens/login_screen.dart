import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/iptv_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _xtreamFormKey = GlobalKey<FormState>();
  final _m3uFormKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uController.dispose();
    super.dispose();
  }

  Future<void> _loginXtream() async {
    if (!_xtreamFormKey.currentState!.validate()) return;
    final provider = Provider.of<IptvProvider>(context, listen: false);
    final success = await provider.loginWithXtream(
      _serverController.text.trim(),
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showError(provider.errorMessage);
    }
  }

  Future<void> _loginM3u() async {
    if (!_m3uFormKey.currentState!.validate()) return;
    final provider = Provider.of<IptvProvider>(context, listen: false);
    final success = await provider.loginWithM3u(_m3uController.text.trim());
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showError(provider.errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0a0a0a), Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow animation
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00d4ff), Color(0xFF0099cc), Color(0xFF0077aa)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00d4ff).withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_circle_fill, size: 55, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'XTREAM IPTV',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00d4ff).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3), width: 1),
                    ),
                    child: const Text(
                      'Sin VIP \u2022 Sin Anuncios \u2022 100% Libre',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00d4ff),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0f1a2e),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1a2a4e), width: 1),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00d4ff), Color(0xFF0099cc)],
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(
                          height: 42,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login, size: 16),
                              SizedBox(width: 6),
                              Text('Xtream Codes'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 42,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.playlist_play, size: 16),
                              SizedBox(width: 6),
                              Text('Lista M3U'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tab Views
                  SizedBox(
                    height: 340,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Xtream Login
                        Form(
                          key: _xtreamFormKey,
                          child: Column(
                            children: [
                              _buildInputField(
                                controller: _serverController,
                                hintText: 'http://servidor.com:puerto',
                                prefixIcon: Icons.dns_outlined,
                                validator: (v) => v!.isEmpty ? 'Ingresa el servidor' : null,
                              ),
                              const SizedBox(height: 14),
                              _buildInputField(
                                controller: _usernameController,
                                hintText: 'Nombre de usuario',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => v!.isEmpty ? 'Ingresa el usuario' : null,
                              ),
                              const SizedBox(height: 14),
                              _buildInputField(
                                controller: _passwordController,
                                hintText: 'Contraseña',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) => v!.isEmpty ? 'Ingresa la contraseña' : null,
                              ),
                              const SizedBox(height: 24),
                              Consumer<IptvProvider>(
                                builder: (_, provider, __) {
                                  return _buildConnectButton(
                                    onPressed: provider.isLoading ? null : _loginXtream,
                                    isLoading: provider.isLoading,
                                    label: 'CONECTAR',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // M3U Login
                        Form(
                          key: _m3uFormKey,
                          child: Column(
                            children: [
                              _buildInputField(
                                controller: _m3uController,
                                hintText: 'Pega aqui la URL de tu lista M3U',
                                prefixIcon: Icons.link_outlined,
                                maxLines: 4,
                                validator: (v) => v!.isEmpty ? 'Ingresa la URL M3U' : null,
                              ),
                              const SizedBox(height: 24),
                              Consumer<IptvProvider>(
                                builder: (_, provider, __) {
                                  return _buildConnectButton(
                                    onPressed: provider.isLoading ? null : _loginM3u,
                                    isLoading: provider.isLoading,
                                    label: 'CARGAR LISTA',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
          child: Icon(prefixIcon, color: const Color(0xFF00d4ff), size: 20),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0f1a2e),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1a2a4e), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00d4ff), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildConnectButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: onPressed != null
              ? const LinearGradient(
                  colors: [Color(0xFF00d4ff), Color(0xFF0099cc)],
                )
              : null,
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: const Color(0xFF00d4ff).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          child: isLoading
              ? const SpinKitThreeBounce(color: Colors.white, size: 20)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.power_settings_new, size: 20),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}
