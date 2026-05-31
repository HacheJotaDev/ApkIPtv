import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import 'connection_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // App info header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF2A2A4A)])),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/images/logo.png', width: 64, height: 64, fit: BoxFit.cover)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HacheJota IPTV', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('v2.0.0', style: TextStyle(color: Colors.grey, fontSize: 14)), SizedBox(height: 2), Text('Sin anuncios · Sin VIP · Todo libre', style: TextStyle(color: Color(0xFFE50914), fontSize: 12))])),
              ],
            ),
          ),

          // Connection section
          _SectionTitle(title: 'Conexion'),
          
          if (appState.credentials != null)
            _SettingsTile(icon: Icons.dns, title: 'Servidor Xtream', subtitle: appState.credentials!.server, trailing: const Icon(Icons.check_circle, color: Colors.green)),
          
          if (appState.m3uUrl.isNotEmpty)
            _SettingsTile(icon: Icons.link, title: 'Lista M3U', subtitle: appState.m3uUrl.length > 40 ? '${appState.m3uUrl.substring(0, 40)}...' : appState.m3uUrl, trailing: const Icon(Icons.check_circle, color: Colors.green)),

          _SettingsTile(
            icon: Icons.add_circle_outline,
            title: 'Cambiar Conexion',
            subtitle: 'Conectar a otro servidor o lista M3U',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectionSetupScreen())),
          ),

          _SettingsTile(
            icon: Icons.refresh,
            title: 'Recargar Datos',
            subtitle: 'Volver a cargar canales y peliculas',
            onTap: () async {
              await appState.autoReconnect();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appState.statusMessage), backgroundColor: Colors.green));
              }
            },
          ),

          _SettingsTile(
            icon: Icons.cloud_off,
            title: 'Desconectar',
            subtitle: 'Eliminar conexion actual',
            titleColor: const Color(0xFFE50914),
            onTap: () => _showDisconnectDialog(context),
          ),

          // Stats section
          _SectionTitle(title: 'Estadisticas'),
          
          _SettingsTile(icon: Icons.live_tv, title: 'Canales en Vivo', subtitle: '${appState.channels.length} canales cargados'),
          _SettingsTile(icon: Icons.movie, title: 'Peliculas', subtitle: '${appState.movies.length} peliculas cargadas'),
          _SettingsTile(icon: Icons.tv, title: 'Series', subtitle: '${appState.series.length} series cargadas'),
          _SettingsTile(icon: Icons.favorite, title: 'Favoritos', subtitle: '${appState.favoriteChannels.length} canales · ${appState.favoriteMovies.length} peliculas · ${appState.favoriteSeries.length} series'),

          // Player section
          _SectionTitle(title: 'Reproductor'),
          _SettingsTile(icon: Icons.play_circle, title: 'Reproductor Integrado', subtitle: 'Reproduccion directa con media_kit'),
          _SettingsTile(icon: Icons.open_in_new, title: 'Reproductor Externo', subtitle: 'Opcion disponible en el reproductor'),

          // About section
          _SectionTitle(title: 'Acerca de'),
          _SettingsTile(icon: Icons.info_outline, title: 'Acerca de HacheJota IPTV', subtitle: 'Aplicacion de IPTV gratuita, sin anuncios y sin restricciones VIP. Disfruta de canales en vivo, peliculas y series sin limitaciones.'),
          _SettingsTile(icon: Icons.code, title: 'Codigo Abierto', subtitle: 'Esta aplicacion fue creada desde cero con Flutter.'),
          _SettingsTile(icon: Icons.shield, title: 'Privacidad', subtitle: 'No se recopilan datos personales. No hay anuncios ni rastreadores.'),

          const SizedBox(height: 40),
          Center(child: Column(children: [Text('Hecho con amor por HacheJota', style: TextStyle(color: Colors.grey[500], fontSize: 13)), const SizedBox(height: 4), Text('2024-2026 - Todos los derechos reservados', style: TextStyle(color: Colors.grey[600], fontSize: 11))])),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Desconectar', style: TextStyle(color: Colors.white)),
        content: const Text('Estas seguro de que quieres desconectar tu servicio IPTV? Se eliminaran todos los datos de conexion.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () async { await appState.disconnect(); if (context.mounted) Navigator.pop(context); }, child: const Text('Desconectar', style: TextStyle(color: Color(0xFFE50914)))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.trailing, this.titleColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? const Color(0xFFE50914)),
      title: Text(title, style: TextStyle(color: titleColor ?? Colors.white, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: Colors.grey[400], fontSize: 12)) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey) : null),
      onTap: onTap,
    );
  }
}
