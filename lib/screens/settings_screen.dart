import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IptvProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account info
          if (provider.userInfo != null) ...[
            _SectionHeader(title: 'Cuenta'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                if (provider.credentials != null) ...[
                  _ProfileHeader(
                    username: provider.credentials!.username,
                    server: provider.credentials!.baseUrl,
                    connectionType: provider.connectionType,
                  ),
                  const Divider(color: Color(0xFF1a2a5e), height: 1),
                ],
                _SettingsTile(
                  icon: Icons.link_outlined,
                  title: 'Conexion',
                  subtitle: provider.connectionType == 'xtream' ? 'Xtream Codes' : 'Lista M3U',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00b0ff).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVO',
                      style: TextStyle(color: Color(0xFF00b0ff), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (provider.userInfo?['exp_date'] != null)
                  _SettingsTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Expiracion',
                    subtitle: _formatDate(provider.userInfo!['exp_date'].toString()),
                  ),
                if (provider.userInfo?['max_connections'] != null)
                  _SettingsTile(
                    icon: Icons.devices_outlined,
                    title: 'Conexiones maximas',
                    subtitle: provider.userInfo!['max_connections'].toString(),
                  ),
                if (provider.userInfo?['active_cons'] != null)
                  _SettingsTile(
                    icon: Icons.wifi_outlined,
                    title: 'Conexiones activas',
                    subtitle: provider.userInfo!['active_cons'].toString(),
                  ),
              ],
            ),
          ],

          // Content stats
          _SectionHeader(title: 'Contenido'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.live_tv_outlined,
                title: 'Canales en vivo',
                subtitle: '${provider.liveChannels.length} canales',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00b0ff).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${provider.liveCategories.length} cat.',
                    style: const TextStyle(color: Color(0xFF00b0ff), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.movie_outlined,
                title: 'Peliculas',
                subtitle: '${provider.vodMovies.length} peliculas',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00b0ff).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${provider.vodCategories.length} cat.',
                    style: const TextStyle(color: Color(0xFF00b0ff), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.tv_outlined,
                title: 'Series',
                subtitle: '${provider.seriesList.length} series',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00b0ff).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${provider.seriesCategories.length} cat.',
                    style: const TextStyle(color: Color(0xFF00b0ff), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // App info
          _SectionHeader(title: 'Aplicacion'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.block_outlined,
                title: 'Anuncios',
                subtitle: 'Sin anuncios - Libre de publicidad',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('ACTIVO', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.verified_outlined,
                title: 'VIP',
                subtitle: 'Sin restricciones - Todo desbloqueado',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('ACTIVO', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // HacheJota Developer Credit
          _SectionHeader(title: 'Desarrollador'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00e5ff), Color(0xFF0066ff)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00b0ff).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.code, color: Colors.white, size: 32);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00e5ff), Color(0xFF0066ff)],
                      ).createShader(bounds),
                      child: const Text(
                        'HacheJota',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Desarrollador de Software',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00b0ff).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00b0ff).withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, color: Color(0xFF00b0ff), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Hecho con dedicacion',
                            style: TextStyle(color: Color(0xFF00b0ff), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.4), width: 1),
              ),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF0f0f2e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF1a2a5e)),
                      ),
                      title: const Text('Cerrar sesion', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'Estas seguro de que quieres cerrar sesion?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Cerrar sesion', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await provider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LoginScreen(),
                          transitionDuration: const Duration(milliseconds: 400),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('CERRAR SESION'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return timestamp;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String username;
  final String server;
  final String connectionType;

  const _ProfileHeader({
    required this.username,
    required this.server,
    required this.connectionType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00b0ff), Color(0xFF0066ff)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00b0ff).withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  server.replaceAll('http://', '').replaceAll('https://', ''),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00b0ff),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0f0f2e),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1a2a5e).withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF00b0ff).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF00b0ff), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: trailing,
    );
  }
}
