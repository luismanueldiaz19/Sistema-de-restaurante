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
    final textTheme = Theme.of(context).textTheme;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No hay sesión activa')));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.azulOscuro,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Header Card (Avatar & Name)
            FadeInDown(
              child: _buildHeaderCard(user.name ?? 'Usuario', user.email ?? '', textTheme),
            ),

            const SizedBox(height: 24),

            // 2. Roles Section
            FadeInLeft(
              delay: const Duration(milliseconds: 200),
              child: _buildSectionTitle('Roles del Sistema', Icons.admin_panel_settings_rounded),
            ),
            const SizedBox(height: 12),
            FadeInLeft(
              delay: const Duration(milliseconds: 300),
              child: _buildChipsList(auth.roles, Colors.blueAccent),
            ),

            const SizedBox(height: 32),

            // 3. Permissions Section
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildSectionTitle('Permisos Habilitados', Icons.vpn_key_rounded),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildPermissionsGrid(auth.permissions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String name, String email, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.azulOscuro,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.azulOscuro),
          ),
          Text(
            email,
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.azulOscuro, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulOscuro),
        ),
      ],
    );
  }

  Widget _buildChipsList(List<String> items, Color color) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            item.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionsGrid(List<String> permissions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: permissions.map((p) => _buildPermissionBadge(p)).toList(),
      ),
    );
  }

  Widget _buildPermissionBadge(String permission) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          Text(
            permission.replaceAll('_', ' '),
            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
