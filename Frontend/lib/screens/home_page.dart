import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/facturacion/screens/add_factura.dart';
import 'package:sistema_restaurante/modulo_cliente/screens/screen_client_admin.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_productos.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_ingredientes.dart';
import 'package:sistema_restaurante/screens/profile_screen.dart';
import 'package:sistema_restaurante/widgets/custom_confirm_dialog.dart';
import 'package:sistema_restaurante/widgets/custom_sidebar.dart';
import '../facturacion/screens/reporte_ventas_screen.dart';
import '../modulo_cliente/providers/cliente_admin_provider.dart';
import '../modulo_caja/providers/caja_provider.dart';
import '../modulo_caja/widgets/cierre_caja_dialog.dart';
import '../modulo_nomina/providers/nomina_provider.dart';
import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../utils/helpers.dart';
import 'dashboard_buttons_section/dashboard_buttons_section.dart';
import 'login_page.dart';
import '../facturacion/screens/historial_caja_screen.dart';
import '../facturacion/screens/historial_ventas_screen.dart';
import '../modulo_nomina/screens/nomina_dashboard_screen.dart';
import '../modulo_nomina/screens/add_nomina_screen.dart';
import '../modulo_nomina/screens/empleado_list_screen.dart';

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

  void _handleCierreCaja(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authProvider);

    // 1. Obtener el resumen del servidor
    final resumenResult = await ref
        .read(cajaProvider.notifier)
        .getResumen(auth.token!);

    if (!resumenResult['success'] && mounted) {
      showToast(
        context,
        'Error al obtener resumen: ${resumenResult['message']}',
        bgColor: Colors.red,
      );
      return;
    }

    final double montoEsperado =
        (resumenResult['data']['monto_esperado_efectivo'] as num).toDouble();

    final List<dynamic> ventasPorMetodo =
        resumenResult['data']['ventas_por_metodo'] ?? [];

    // 2. Mostrar Diálogo de Arqueo
    if (!mounted) return;
    final arqueoData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CierreCajaDialog(
        montoEsperado: montoEsperado,
        ventasPorMetodo: ventasPorMetodo,
      ),
    );

    if (arqueoData == null) return;

    // 3. Ejecutar Cierre en el Servidor
    final result = await ref
        .read(cajaProvider.notifier)
        .cerrarCaja(
          token: auth.token!,
          montoFisico: arqueoData['monto_fisico'],
          desglose: arqueoData['desglose'],
          comentario: arqueoData['comentario'],
        );

    if (result['success'] && mounted) {
      showToast(context, 'CAJA CERRADA EXITOSAMENTE', bgColor: Colors.green);
    } else if (mounted) {
      showToast(context, 'Error: ${result['message']}', bgColor: Colors.red);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.token != null) {
        ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);
        ref.read(cajaProvider.notifier).checkEstado(auth.token!);
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
            SidebarSubItem(
              title: 'Historial de Ventas',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistorialVentasScreen(),
                ),
              ),
            ),
            SidebarSubItem(
              title: 'Historial de Cajas',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialCajaScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Reportes Agrupados',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReporteVentasScreen()),
              ),
            ),
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

      // Módulo de Productos

      // Módulo de Inventario
      if (auth.hasPermission('ver_inventario'))
        SidebarItem(
          title: 'Inventario',
          icon: Icons.inventory_2_outlined,
          subItems: [
            SidebarSubItem(
              title: 'Productos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScreenProductos()),
              ),
            ),
            SidebarSubItem(
              title: 'Ingredientes (Materia Prima)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScreenIngredientes()),
              ),
            ),
            SidebarSubItem(title: 'Ajuste de Inventario', onTap: () {}),

            SidebarSubItem(title: 'Reporte de Stock', onTap: () {}),
            SidebarSubItem(title: 'Kardex de Movimientos', onTap: () {}),
          ],
        ),

      // Reportes y Usuarios (Solo Admin)
      if (auth.hasPermission('gestionar_usuarios'))
        SidebarItem(
          title: 'Usuarios',
          icon: Icons.manage_accounts_outlined,
          onTap: () {},
        ),

      // Módulo de Nómina (Contabilidad)
      if (auth.roles.contains('admin') ||
          auth.roles.contains('contador') ||
          auth.roles.contains('auxiliar contable') ||
          auth.hasPermission('ver_nomina'))
        SidebarItem(
          title: 'Nómina',
          icon: Icons.account_balance_outlined,
          subItems: [
            SidebarSubItem(
              title: 'Dashboard Nómina',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NominaDashboardScreen(),
                ),
              ),
            ),
            SidebarSubItem(
              title: 'Gestionar Empleados',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmpleadoListScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Generar Nómina',
              onTap: () async {
                final result = await showDialog(
                  context: context,
                  builder: (_) => const AddNominaDialog(),
                );
                // Si se generó con éxito, recargar historial
                if (result == true && context.mounted) {
                  ref.read(nominaProvider.notifier).fetchHistorial();
                }
              },
            ),
          ],
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
                      case 'productos':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScreenProductos(),
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
              Consumer(
                builder: (context, ref, _) {
                  final cajaState = ref.watch(cajaProvider);
                  final session = cajaState.sesionActiva;
                  final bool isCajaAbierta = session != null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          if (isCajaAbierta)
                            ElevatedButton.icon(
                              onPressed: () => _handleCierreCaja(context, ref),
                              icon: const Icon(
                                Icons.lock_clock_rounded,
                                size: 16,
                              ),
                              label: const Text('CERRAR CAJA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                              value: isCajaAbierta ? 'ABIERTA' : 'CERRADA',
                              subtitle: isCajaAbierta
                                  ? 'Desde: ${session['fecha_apertura']}'
                                  : 'No hay turno activo',
                              icon: isCajaAbierta
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                              color: isCajaAbierta ? Colors.green : Colors.grey,
                              width: 280,
                            ),
                            const SizedBox(width: 20),
                            if (isCajaAbierta) ...[
                              _buildInfoCard(
                                title: 'Fondo Inicial',
                                value: 'RD\$ ${session['monto_inicial']}',
                                subtitle: 'Base en efectivo',
                                icon: Icons.account_balance_wallet_rounded,
                                color: Colors.blue,
                                width: 280,
                              ),
                              const SizedBox(width: 20),
                              _buildInfoCard(
                                title: 'Cajero Responsable',
                                value: auth.user?.name ?? 'N/A',
                                subtitle: 'Sesión ID: #${session['id']}',
                                icon: Icons.person_rounded,
                                color: Colors.orange,
                                width: 280,
                              ),
                            ] else
                              _buildInfoCard(
                                title: 'Aviso',
                                value: 'Requiere Apertura',
                                subtitle: 'Inicie turno para facturar',
                                icon: Icons.info_outline,
                                color: Colors.red,
                                width: 280,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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

  Widget _buildSessionInfo(
    BuildContext context,
    WidgetRef ref,
    dynamic sesion,
  ) {
    final cajaState = ref.watch(cajaProvider);
    final resumen = cajaState.resumenSesion;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel de Caja',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    'Resumen de operaciones en tiempo real',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: () {
                      final auth = ref.read(authProvider);
                      ref.read(cajaProvider.notifier).fetchResumen(auth.token!);
                    },
                    tooltip: 'Actualizar Datos',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _handleCierreCaja(context, ref),
                    icon: const Icon(Icons.no_meeting_room_rounded, size: 18),
                    label: const Text('CERRAR CAJA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 📊 GRID DE TARJETAS
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 800 ? 2 : 4;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _infoCard(
                    'Estado',
                    'ABIERTA',
                    subtitle:
                        'Desde: ${formatFechaHora(DateTime.parse(sesion['fecha_apertura']))}',
                    icon: Icons.lock_open_rounded,
                    color: Colors.green,
                  ),
                  _infoCard(
                    'Total Ventas',
                    formatCurrency(
                      double.parse(
                        (resumen?['totales_generales']?['total_venta'] ?? 0)
                            .toString(),
                      ),
                    ),
                    subtitle:
                        '${resumen?['totales_generales']?['cantidad_facturas'] ?? 0} facturas generadas',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.primary,
                  ),
                  _infoCard(
                    'Efectivo en Caja',
                    formatCurrency(
                      double.parse(
                        (resumen?['monto_esperado_efectivo'] ??
                                sesion['monto_inicial'])
                            .toString(),
                      ),
                    ),
                    subtitle: 'Incluye RD\$ ${sesion['monto_inicial']} fondo',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.blue,
                  ),
                  _infoCard(
                    'Ventas a Crédito',
                    formatCurrency(_getTotalCredito(resumen)),
                    subtitle: 'Cuentas por cobrar hoy',
                    icon: Icons.timer_outlined,
                    color: Colors.orange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 🔎 DETALLE ADICIONAL
          if (resumen != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  _miniStat(
                    'Ventas Contado',
                    '${_getTotalContado(resumen)}',
                    Icons.monetization_on_outlined,
                    Colors.green,
                  ),
                  _verticalDivider(),
                  _miniStat(
                    'Impuestos (ITBIS)',
                    '${resumen['totales_generales']?['total_itbis'] ?? 0}',
                    Icons.account_balance_outlined,
                    Colors.indigo,
                  ),
                  _verticalDivider(),
                  _miniStat(
                    'Cajero',
                    sesion['usuario']?['name'] ?? 'N/A',
                    Icons.person_outline_rounded,
                    Colors.grey.shade600,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _getTotalCredito(Map<String, dynamic>? resumen) {
    if (resumen == null || resumen['ventas_por_tipo'] == null) return 0;
    final list = resumen['ventas_por_tipo'] as List;
    final item = list.where((e) => e['tipo_factura'] == 'credito').firstOrNull;
    return double.parse((item?['total'] ?? 0).toString());
  }

  double _getTotalContado(Map<String, dynamic>? resumen) {
    if (resumen == null || resumen['ventas_por_tipo'] == null) return 0;
    final list = resumen['ventas_por_tipo'] as List;
    final item = list.where((e) => e['tipo_factura'] == 'contado').firstOrNull;
    return double.parse((item?['total'] ?? 0).toString());
  }

  Widget _verticalDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.grey.shade300,
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.azulOscuro,
                ),
              ),
            ],
          ),
        ],
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
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
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
                Expanded(
                  child: _buildBreakdownItem(
                    'Efectivo',
                    efectivo,
                    Colors.green,
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: _buildBreakdownItem('Tarjeta', tarjeta, Colors.blue),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownItem('Cheque', cheque, Colors.orange),
                ),
                const VerticalDivider(),
                Expanded(
                  child: _buildBreakdownItem('Otros', otros, Colors.purple),
                ),
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
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
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

  Widget _infoCard(
    String title,
    String value, {
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
