import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/facturacion/screens/add_factura.dart';
import 'package:sistema_restaurante/modulo_cliente/screens/screen_client_admin.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_productos.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/crear_cotizacion_screen.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/historial_cotizaciones_screen.dart';
import 'package:sistema_restaurante/modulo_ordenes_compra/screens/crear_orden_compra_screen.dart';
import 'package:sistema_restaurante/modulo_ordenes_compra/screens/historial_ordenes_compra_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/cxp_list_screen.dart';
import 'package:sistema_restaurante/modulo_cxc/screens/cxc_list_screen.dart';
import 'package:sistema_restaurante/widgets/custom_confirm_dialog.dart';
import 'package:sistema_restaurante/widgets/custom_sidebar.dart';
import '../modulo_cliente/providers/cliente_admin_provider.dart';
import '../modulo_caja/providers/caja_provider.dart';
import '../modulo_caja/widgets/cierre_caja_dialog.dart';
import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../utils/helpers.dart';
import '../modulo_menu/menu_builder.dart';
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

    // Definición de Menús Dinámica externalizada
    final menuItems = MenuBuilder.buildMenu(
      context: context,
      auth: auth,
      ref: ref,
      onDashboardTap: () => setState(() => _selectedIndex = 0),
    );

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
                      case 'crear_cotizacion':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrearCotizacionScreen(),
                          ),
                        );
                        break;
                      case 'ver_cotizaciones':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistorialCotizacionesScreen(),
                          ),
                        );
                        break;
                      case 'crear_orden_compra':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrearOrdenCompraScreen(),
                          ),
                        );
                        break;
                      case 'ver_ordenes_compra':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const HistorialOrdenesCompraScreen(),
                          ),
                        );
                        break;
                      case 'ver_cxp':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CxpListScreen(),
                          ),
                        );
                        break;
                      case 'ver_cxc':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CxcListScreen(),
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
