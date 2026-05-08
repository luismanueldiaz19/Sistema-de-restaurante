import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/facturacion/screens/add_factura.dart';
import 'package:sistema_restaurante/modulo_cliente/screens/screen_client_admin.dart';
import 'package:sistema_restaurante/screens/profile_screen.dart';
import 'package:sistema_restaurante/widgets/custom_confirm_dialog.dart';
import 'package:sistema_restaurante/widgets/custom_sidebar.dart';
import '../modulo_cliente/providers/cliente_admin_provider.dart';
import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../utils/helpers.dart';
import 'dashboard_buttons_section/dashboard_buttons_section.dart';
import 'login_page.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});
  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _handleLogout() async {
    final bool? confirm = await CustomConfirmDialog.show(
      context,
      title: 'Salir de la sección',
      message:
          '¿Estás seguro que deseas cerrar sesión? Perderás el acceso hasta que vuelvas a ingresar.',
      confirmText: 'Salir',
      cancelText: 'Volver',
      icon: Icons.logout_rounded,
      primaryColor: Colors.redAccent,
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.token != null) {
        ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    // Definición de Menús Dinámica
    final menuItems = [
      SidebarItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        onTap: () => setState(() => _selectedIndex = 0),
      ),
      SidebarItem(
        title: 'Mi Perfil',
        icon: Icons.person_pin_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),

      // Módulo de Ventas
      if (auth.hasPermission('ver_facturas'))
        SidebarItem(
          title: 'Ventas',
          icon: Icons.shopping_cart_outlined,
          subItems: [
            if (auth.hasPermission('crear_facturas'))
              SidebarSubItem(
                title: 'Nueva Venta',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearFacturaPage()),
                ),
              ),
            SidebarSubItem(title: 'Historial de Ventas', onTap: () {}),
          ],
        ),

      // Módulo de Clientes
      if (auth.hasPermission('ver_clientes'))
        SidebarItem(
          title: 'Clientes',
          icon: Icons.people_outline,
          subItems: [
            SidebarSubItem(
              title: 'Administrar Clientes',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScreenClientAdmin()),
              ),
            ),
            SidebarSubItem(title: 'Reporte de Clientes', onTap: () {}),
          ],
        ),

      // Módulo de Inventario
      if (auth.hasPermission('ver_gastos'))
        SidebarItem(
          title: 'Inventario',
          icon: Icons.inventory_2_outlined,
          subItems: [
            SidebarSubItem(title: 'Stock Actual', onTap: () {}),
            SidebarSubItem(title: 'Ajuste de Inventario', onTap: () {}),
          ],
        ),

      // Reportes y Usuarios (Solo Admin)
      if (auth.hasPermission('gestionar_usuarios'))
        SidebarItem(
          title: 'Usuarios',
          icon: Icons.manage_accounts_outlined,
          onTap: () {},
        ),

      if (auth.hasPermission('ver_gastos')) // Solo quienes ven gastos/reportes
        SidebarItem(
          title: 'Reportes',
          icon: Icons.bar_chart_outlined,
          onTap: () => setState(() => _selectedIndex = 4),
        ),
    ];

    return Scaffold(
      key: scaffoldKey,
      drawer: !isDesktop
          ? CustomSidebar(
              selectedIndex: _selectedIndex,
              items: menuItems,
              onLogout: _handleLogout,
              userName: auth.user?.name ?? 'Usuario', // 👈 Nombre dinámico
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              },
            )
          : null,
      body: Row(
        children: [
          // 1. Sidebar (Solo en Desktop)
          if (isDesktop)
            CustomSidebar(
              selectedIndex: _selectedIndex,
              items: menuItems,
              onLogout: _handleLogout,
              userName: auth.user?.name ?? 'Usuario', // 👈 Nombre dinámico
              onItemSelected: (index) => setState(() => _selectedIndex = index),
            ),

          // 2. Main Content
          Expanded(
            child: Column(
              children: [
                // Custom Header / AppBar
                _buildHeader(isDesktop, auth),

                // Content Area
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _buildCurrentScreen(auth),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, AuthState auth) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
          Text(
            _getPageTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.azulOscuro,
            ),
          ),
          const Spacer(),
          // User Info & Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 15),
                Text(
                  auth.user?.name ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Principal';
      case 1:
        return 'Módulo de Ventas';
      case 2:
        return 'Gestión de Clientes';
      case 3:
        return 'Inventario y Stock';
      case 4:
        return 'Reportes Generales';
      default:
        return 'Menuxa';
    }
  }

  Widget _buildCurrentScreen(AuthState auth) {
    if (_selectedIndex == 0) {
      return Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Parte Superior (Botones de Acceso Rápido)
            Expanded(
              child: SingleChildScrollView(
                child: DashboardButtonsSection(
                  onAction: (action) {
                    switch (action) {
                      case 'venta':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrearFacturaPage(),
                          ),
                        );
                        break;
                      case 'clientes':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScreenClientAdmin(),
                          ),
                        );
                        break;
                      default:
                        showToast(
                          context,
                          'Módulo en desarrollo',
                          bgColor: Colors.blueGrey,
                        );
                    }
                  },
                ),
              ),
            ),

            // 2. Separador y Sección de Caja (Siempre abajo y Horizontal)
            if (auth.hasPermission('ver_facturas')) ...[
              const Divider(height: 20, thickness: 0.1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Información de Caja',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.azulOscuro,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Imprimir X', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildInfoCard(
                      title: 'Estado de Caja',
                      value: 'ABIERTA',
                      subtitle: 'Turno Mañana',
                      icon: Icons.lock_open_rounded,
                      color: Colors.green,
                      width: 280,
                    ),
                    const SizedBox(width: 20),
                    _buildPaymentBreakdownCard(
                      efectivo: '8,450.00',
                      tarjeta: '4,000.00',
                      cheque: '0.00',
                      otros: '0.00',
                      width: 400,
                    ),
                    const SizedBox(width: 20),
                    _buildInfoCard(
                      title: 'Ventas de Hoy',
                      value: 'RD\$ 12,450.00',
                      subtitle: '14 transacciones',
                      icon: Icons.payments_rounded,
                      color: Colors.blue,
                      width: 280,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Text(
        'Pantalla en Desarrollo: ${_getPageTitle()}',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return FadeInRight(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.azulOscuro,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBreakdownCard({
    required String efectivo,
    required String tarjeta,
    required String cheque,
    required String otros,
    required double width,
  }) {
    return FadeInRight(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Desglose por Métodos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildBreakdownItem('Efectivo', efectivo, Colors.green)),
                const VerticalDivider(),
                Expanded(child: _buildBreakdownItem('Tarjeta', tarjeta, Colors.blue)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Row(
              children: [
                Expanded(child: _buildBreakdownItem('Cheque', cheque, Colors.orange)),
                const VerticalDivider(),
                Expanded(child: _buildBreakdownItem('Otros', otros, Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          'RD\$ $amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
      ],
    );
  }
}
