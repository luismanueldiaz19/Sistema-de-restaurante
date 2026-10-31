import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No hay sesión activa')));
    }

    // Identificar el rol principal para el tema visual
    String primaryRole = 'usuario';
    final roles = auth.roles.map((r) => r.toLowerCase()).toList();
    if (roles.contains('admin')) {
      primaryRole = 'admin';
    } else if (roles.contains('cajero')) {
      primaryRole = 'cajero';
    } else if (roles.contains('contador')) {
      primaryRole = 'contador';
    } else if (roles.isNotEmpty) {
      primaryRole = roles.first;
    }

    // Configuración del tema basado en el rol
    List<Color> gradientColors;
    IconData roleIcon;
    String roleLabel;

    switch (primaryRole) {
      case 'admin':
        gradientColors = [
          const Color(0xFF1E3A8A),
          const Color(0xFF3B82F6),
        ]; // Azul Profundo
        roleIcon = Icons.admin_panel_settings_rounded;
        roleLabel = 'Administrador del Sistema';
        break;
      case 'cajero':
        gradientColors = [
          const Color(0xFF047857),
          const Color(0xFF10B981),
        ]; // Verde Esmeralda
        roleIcon = Icons.point_of_sale_rounded;
        roleLabel = 'Cajero / Facturación';
        break;
      case 'contador':
        gradientColors = [
          const Color(0xFF4338CA),
          const Color(0xFF6366F1),
        ]; // Indigo
        roleIcon = Icons.account_balance_rounded;
        roleLabel = 'Contabilidad y Finanzas';
        break;
      default:
        gradientColors = [
          const Color(0xFF374151),
          const Color(0xFF6B7280),
        ]; // Gris oscuro
        roleIcon = Icons.person_rounded;
        roleLabel = 'Usuario Estándar';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header con degradado (Dependiente del Rol)
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: gradientColors.last.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          user.name != null && user.name!.isNotEmpty
                              ? user.name![0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 45,
                            color: gradientColors.first,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70),

            // 2. Información del Usuario y Rol
            FadeInUp(
              child: Column(
                children: [
                  Text(
                    user.name ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user.email ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: gradientColors.last.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: gradientColors.last.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, size: 20, color: gradientColors.first),
                        const SizedBox(width: 8),
                        Text(
                          roleLabel.toUpperCase(),
                          style: TextStyle(
                            color: gradientColors.first,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 3. Sección de Permisos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: _buildSectionTitle(
                      'Permisos Asignados',
                      Icons.vpn_key_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _buildPermissionsCard(auth.permissions),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.azulOscuro.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.azulOscuro, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsCard(List<String> permissions) {
    if (permissions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'No tienes permisos específicos asignados.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: permissions.map((p) => _buildPermissionBadge(p)).toList(),
      ),
    );
  }

  Widget _buildPermissionBadge(String permission) {
    // Colores dinámicos sutiles para diferenciar un poco los permisos
    final colors = [
      Colors.teal,
      Colors.indigo,
      Colors.blue,
      Colors.orange.shade800,
      Colors.deepPurple,
    ];
    final color = colors[permission.length % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            permission.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
