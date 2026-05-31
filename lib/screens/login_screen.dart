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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: Colors.red,
        ),
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
                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00d4ff), Color(0xFF0099cc)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00d4ff).withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'XTREAM IPTV',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Conecta tu servicio IPTV',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213e),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF00d4ff),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Xtream Codes'),
                        Tab(text: 'Lista M3U'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Views
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Xtream Login
                        Form(
                          key: _xtreamFormKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _serverController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'http://servidor.com:puerto',
                                  prefixIcon: Icon(Icons.dns, color: Color(0xFF00d4ff)),
                                ),
                                validator: (v) => v!.isEmpty ? 'Ingresa el servidor' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Nombre de usuario',
                                  prefixIcon: Icon(Icons.person, color: Color(0xFF00d4ff)),
                                ),
                                validator: (v) => v!.isEmpty ? 'Ingresa el usuario' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF00d4ff)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => v!.isEmpty ? 'Ingresa la contraseña' : null,
                              ),
                              const SizedBox(height: 24),
                              Consumer<IptvProvider>(
                                builder: (_, provider, __) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: provider.isLoading ? null : _loginXtream,
                                      child: provider.isLoading
                                          ? const SpinKitThreeBounce(color: Colors.black, size: 20)
                                          : const Text('CONECTAR'),
                                    ),
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
                              TextFormField(
                                controller: _m3uController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Pega aquí la URL de tu lista M3U',
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(bottom: 40),
                                    child: Icon(Icons.link, color: Color(0xFF00d4ff)),
                                  ),
                                ),
                                validator: (v) => v!.isEmpty ? 'Ingresa la URL M3U' : null,
                              ),
                              const SizedBox(height: 24),
                              Consumer<IptvProvider>(
                                builder: (_, provider, __) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: provider.isLoading ? null : _loginM3u,
                                      child: provider.isLoading
                                          ? const SpinKitThreeBounce(color: Colors.black, size: 20)
                                          : const Text('CARGAR LISTA'),
                                    ),
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
}
