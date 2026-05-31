import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/iptv_models.dart';
import '../services/iptv_service.dart';

class ConnectionSetupScreen extends StatefulWidget {
  const ConnectionSetupScreen({super.key});

  @override
  State<ConnectionSetupScreen> createState() => _ConnectionSetupScreenState();
}

class _ConnectionSetupScreenState extends State<ConnectionSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uController = TextEditingController();
  final _service = IptvService();
  bool _isConnecting = false;
  bool _obscurePassword = true;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.credentials != null) {
        _serverController.text = appState.credentials!.server;
        _usernameController.text = appState.credentials!.username;
        _passwordController.text = appState.credentials!.password;
      }
      if (appState.m3uUrl.isNotEmpty) {
        _m3uController.text = appState.m3uUrl;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar IPTV'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE50914),
          labelColor: const Color(0xFFE50914),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Xtream Codes', icon: Icon(Icons.dns)),
            Tab(text: 'Lista M3U', icon: Icon(Icons.link)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildXtreamTab(), _buildM3uTab()],
      ),
    );
  }

  Widget _buildXtreamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFFE50914).withOpacity(0.3), blurRadius: 20)]), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)))),
            const SizedBox(height: 24),
            const Text('Conectar con Xtream Codes API', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Ingresa los datos de tu proveedor IPTV', style: TextStyle(color: Colors.grey[400], fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextFormField(
              controller: _serverController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'URL del Servidor', labelStyle: TextStyle(color: Colors.grey), hintText: 'http://ejemplo.com:8080', hintStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.dns, color: Color(0xFFE50914))),
              validator: (value) { if (value == null || value.isEmpty) return 'Ingresa la URL del servidor'; if (!value.startsWith('http')) return 'La URL debe empezar con http:// o https://'; return null; },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Usuario', labelStyle: TextStyle(color: Colors.grey), hintText: 'tu_usuario', hintStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.person, color: Color(0xFFE50914))),
              validator: (value) { if (value == null || value.isEmpty) return 'Ingresa tu usuario'; return null; },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contrasena', labelStyle: const TextStyle(color: Colors.grey), hintText: '********', hintStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.lock, color: Color(0xFFE50914)),
                suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
              ),
              validator: (value) { if (value == null || value.isEmpty) return 'Ingresa tu contrasena'; return null; },
            ),
            const SizedBox(height: 8),
            if (_statusText.isNotEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_statusText, style: TextStyle(color: Colors.grey[400], fontSize: 13), textAlign: TextAlign.center)),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connectXtream,
                child: _isConnecting ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 12), Text('Conectando...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]) : const Text('Conectar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildM3uTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF2A2A4A)), child: const Icon(Icons.link, size: 40, color: Color(0xFFE50914)))),
          const SizedBox(height: 24),
          const Text('Cargar Lista M3U', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Pega la URL de tu lista M3U o M3U8', style: TextStyle(color: Colors.grey[400], fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextFormField(
            controller: _m3uController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'URL de Lista M3U', labelStyle: TextStyle(color: Colors.grey), hintText: 'http://ejemplo.com/lista.m3u', hintStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.link, color: Color(0xFFE50914)), alignLabelWithHint: true),
          ),
          if (_statusText.isNotEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_statusText, style: TextStyle(color: Colors.grey[400], fontSize: 13), textAlign: TextAlign.center)),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isConnecting ? null : _connectM3u,
              child: _isConnecting ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 12), Text('Cargando...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]) : const Text('Cargar Lista', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectXtream() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isConnecting = true; _statusText = 'Probando conexion...'; });
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await appState.setXtreamCredentials(
        _serverController.text.trim().replaceAll(RegExp(r'/$'), ''),
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      final creds = appState.credentials!;
      
      setState(() => _statusText = 'Verificando credenciales...');
      final connected = await _service.testXtreamConnection(creds);
      if (!connected) { if (mounted) { setState(() { _isConnecting = false; _statusText = ''; }); _showError('No se pudo conectar al servidor. Verifica tus datos.'); } return; }

      setState(() => _statusText = 'Cargando canales...');
      appState.setLoading(true);
      
      final results = await Future.wait([
        _service.fetchXtreamLiveChannels(creds),
        _service.fetchXtreamLiveCategories(creds),
        _service.fetchXtreamVod(creds),
        _service.fetchXtreamVodCategories(creds),
        _service.fetchXtreamSeries(creds),
        _service.fetchXtreamSeriesCategories(creds),
      ]);

      final channels = results[0] as List<Channel>;
      final liveCategories = results[1] as Map<String, String>;
      final vodItems = results[2] as List<VodItem>;
      final vodCategories = results[3] as Map<String, String>;
      final seriesItems = results[4] as List<VodItem>;
      final seriesCategories = results[5] as Map<String, String>;

      appState.setChannels(_service.resolveChannelCategories(channels, liveCategories));
      appState.setMovies(_service.resolveVodCategories(vodItems, vodCategories));
      appState.setSeries(_service.resolveVodCategories(seriesItems, seriesCategories));
      appState.setLoading(false);
      appState.setConnected(true);
      appState.setStatusMessage('Cargado: ${channels.length} canales, ${vodItems.length} peliculas, ${seriesItems.length} series');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conectado: ${channels.length} canales, ${vodItems.length} peliculas, ${seriesItems.length} series'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      appState.setLoading(false);
      if (mounted) { setState(() { _isConnecting = false; _statusText = ''; }); _showError('Error: $e'); }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _connectM3u() async {
    final url = _m3uController.text.trim();
    if (url.isEmpty) { _showError('Ingresa una URL valida'); return; }
    if (!url.startsWith('http')) { _showError('La URL debe empezar con http:// o https://'); return; }

    setState(() { _isConnecting = true; _statusText = 'Descargando lista M3U...'; });
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await appState.setM3uUrl(url);
      appState.setLoading(true);
      
      setState(() => _statusText = 'Procesando canales...');
      final results = await _service.parseM3u(url);
      final channels = results[0] as List<Channel>;
      final vodItems = results[1] as List<VodItem>;
      
      final movies = vodItems.where((v) => v.type != 'series').toList();
      final seriesList = vodItems.where((v) => v.type == 'series').toList();
      
      appState.setChannels(channels);
      appState.setMovies(movies);
      appState.setSeries(seriesList);
      appState.setLoading(false);
      appState.setConnected(true);
      appState.setStatusMessage('Cargado: ${channels.length} canales, ${movies.length} peliculas, ${seriesList.length} series');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cargado: ${channels.length} canales, ${movies.length} peliculas, ${seriesList.length} series'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      appState.setLoading(false);
      if (mounted) { setState(() { _isConnecting = false; _statusText = ''; }); _showError('Error al cargar la lista: $e'); }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
  }
}
