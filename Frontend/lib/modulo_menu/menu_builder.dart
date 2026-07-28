import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importaciones de paquetes y utilidades locales
import 'package:sistema_restaurante/providers/auth_state.dart';
import 'package:sistema_restaurante/widgets/custom_sidebar.dart';

// Importaciones de pantallas y dialogos
import 'package:sistema_restaurante/screens/profile_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/add_factura.dart';
import 'package:sistema_restaurante/facturacion/screens/historial_ventas_screen.dart';
import 'package:sistema_restaurante/modulo_cliente/screens/screen_client_admin.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_productos.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_recetas.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_movimientos_inventario.dart';
import 'package:sistema_restaurante/modulo_compras/screens/nueva_compra_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/compras_list_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/proveedores_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/cxp_list_screen.dart';
import '../modulo_compras/screens/historial_pagos_cxp_screen.dart';
import '../modulo_contabilidad/screens/mayor_general_screen.dart';
import '../modulo_contabilidad/screens/balance_general_screen.dart';
import '../modulo_contabilidad/screens/estado_resultados_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/historial_caja_screen.dart';
import 'package:sistema_restaurante/screens/libro_diario_screen.dart';
import 'package:sistema_restaurante/screens/configuracion_contable_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/nomina_dashboard_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/empleado_list_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/add_nomina_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/providers/nomina_provider.dart';
import 'package:sistema_restaurante/modulo_dgii/screens/dgii_dashboard_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/reporte_ventas_screen.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/crear_cotizacion_screen.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/historial_cotizaciones_screen.dart';
import 'package:sistema_restaurante/modulo_ordenes_compra/screens/crear_orden_compra_screen.dart';
import 'package:sistema_restaurante/modulo_ordenes_compra/screens/historial_ordenes_compra_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/gestion_documentos_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/historial_notas_credito_screen.dart';

class MenuBuilder {
  /// Retorna la lista de [SidebarItem] basada en la estructura de módulos de negocio y los permisos del usuario.
  static List<SidebarItem> buildMenu({
    required BuildContext context,
    required AuthState auth,
    required WidgetRef ref,
    required VoidCallback onDashboardTap,
  }) {
    final bool isAdmin = auth.roles.contains('admin');
    final bool isContador = auth.roles.contains('contador');
    final bool isCajero = auth.roles.any((r) => r.toLowerCase() == 'cajero');
    final bool isAuxContable = auth.roles.contains('auxiliar contable');

    return [
      // 1. DASHBOARD
      SidebarItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        onTap: onDashboardTap,
      ),

      // MI PERFIL (Conservado para facilidad de acceso)
      SidebarItem(
        title: 'Mi Perfil',
        icon: Icons.person_pin_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),

      // 2. VENTAS
      if (auth.hasPermission('ver_facturas') ||
          auth.hasPermission('ver_clientes') ||
          isAdmin)
        SidebarItem(
          title: 'Ventas',
          icon: Icons.point_of_sale_outlined,
          subItems: [
            if (auth.hasPermission('crear_facturas') || isAdmin)
              SidebarSubItem(
                title: 'Nueva Cotización',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CrearCotizacionScreen(),
                  ),
                ),
              ),
            if (auth.hasPermission('ver_facturas') || isAdmin)
              SidebarSubItem(
                title: 'Cotizaciones',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialCotizacionesScreen(),
                  ),
                ),
              ),
            SidebarSubItem(title: 'Pedidos', onTap: () {}),
            if (auth.hasPermission('crear_facturas') || isAdmin)
              SidebarSubItem(
                title: 'Nueva Venta',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearFacturaPage()),
                ),
              ),
            if (auth.hasPermission('ver_facturas') || isAdmin)
              SidebarSubItem(
                title: 'Facturas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialVentasScreen(),
                  ),
                ),
              ),
            SidebarSubItem(title: 'Recibos de Pago', onTap: () {}),
            SidebarSubItem(
              title: 'Gestión de Documentos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GestionDocumentosScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Notas de Crédito',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialNotasCreditoScreen()),
              ),
            ),
            if (auth.hasPermission('ver_clientes') || isAdmin)
              SidebarSubItem(
                title: 'Clientes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenClientAdmin()),
                ),
              ),
          ],
        ),

      // 3. INVENTARIO
      if (auth.hasPermission('ver_inventario') ||
          auth.hasPermission('ver_productos') ||
          isAdmin)
        SidebarItem(
          title: 'Inventario',
          icon: Icons.inventory_2_outlined,
          subItems: [
            if (auth.hasPermission('ver_productos') ||
                auth.hasPermission('ver_inventario') ||
                isAdmin)
              SidebarSubItem(
                title: 'Productos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenProductos()),
                ),
              ),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(title: 'Categorías', onTap: () {}),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(title: 'Kardex', onTap: () {}),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(
                title: 'Ajustes de Inventario',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenMovimientosInventario()),
                ),
              ),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(title: 'Transferencias', onTap: () {}),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(
                title: 'Recetas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenRecetas()),
                ),
              ),
          ],
        ),

      // 4. COMPRAS
      if (auth.hasPermission('ver_compras') ||
          auth.hasPermission('ver_proveedores') ||
          isAdmin)
        SidebarItem(
          title: 'Compras',
          icon: Icons.shopping_bag_outlined,
          subItems: [
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Nueva Compra',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevaCompraScreen()),
                ),
              ),
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Nueva O. Compra',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CrearOrdenCompraScreen(),
                  ),
                ),
              ),
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Órdenes de Compra',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialOrdenesCompraScreen(),
                  ),
                ),
              ),
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Historial de Compras',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComprasListScreen()),
                ),
              ),
            if (auth.hasPermission('ver_proveedores') || isAdmin)
              SidebarSubItem(
                title: 'Proveedores',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProveedoresScreen()),
                ),
              ),
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Cuentas por Pagar',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CxpListScreen()),
                ),
              ),
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Pagos Realizados',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialPagosCxpScreen(),
                  ),
                ),
              ),
          ],
        ),

      // 5. FINANZAS
      if (auth.hasPermission('gestionar_caja') ||
          auth.hasPermission('ver_cxc') ||
          auth.hasPermission('ver_gastos') ||
          isAdmin ||
          isCajero ||
          isContador)
        SidebarItem(
          title: 'Finanzas',
          icon: Icons.monetization_on_outlined,
          subItems: [
            if (auth.hasPermission('gestionar_caja') ||
                isAdmin ||
                isCajero) ...[
              SidebarSubItem(title: 'Apertura de Caja', onTap: () {}),
              SidebarSubItem(title: 'Cierre de Caja', onTap: () {}),
              SidebarSubItem(
                title: 'Movimientos de Caja',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialCajaScreen(),
                  ),
                ),
              ),
            ],
            SidebarSubItem(title: 'Bancos', onTap: () {}),
            if (auth.hasPermission('ver_cxc') || isAdmin || isContador)
              SidebarSubItem(title: 'Cuentas por Cobrar', onTap: () {}),
            if (auth.hasPermission('ver_gastos') || isAdmin || isContador)
              SidebarSubItem(title: 'Gastos', onTap: () {}),
          ],
        ),

      // 6. CONTABILIDAD
      if (isAdmin || isContador)
        SidebarItem(
          title: 'Contabilidad',
          icon: Icons.account_balance_rounded,
          subItems: [
            SidebarSubItem(
              title: 'Configuración Contable',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConfiguracionContableScreen(),
                ),
              ),
            ),
            SidebarSubItem(
              title: 'Diario General',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibroDiarioScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Mayor General',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MayorGeneralScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Balance General',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BalanceGeneralScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Estado de Resultados',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EstadoResultadosScreen(),
                ),
              ),
            ),
          ],
        ),

      // 7. RRHH
      if (isAdmin ||
          isContador ||
          isAuxContable ||
          auth.hasPermission('ver_nomina'))
        SidebarItem(
          title: 'RRHH',
          icon: Icons.people_outline,
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
              title: 'Empleados',
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
            SidebarSubItem(title: 'Vacaciones', onTap: () {}),
            SidebarSubItem(title: 'Asistencia', onTap: () {}),
          ],
        ),

      // 8. DGII
      if (isAdmin || isContador)
        SidebarItem(
          title: 'DGII',
          icon: Icons.receipt_outlined,
          subItems: [
            SidebarSubItem(title: 'NCF', onTap: () {}),
            SidebarSubItem(
              title: 'e-CF',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DgiiDashboardScreen()),
              ),
            ),
            SidebarSubItem(title: 'Reporte 606', onTap: () {}),
            SidebarSubItem(title: 'Reporte 607', onTap: () {}),
            SidebarSubItem(title: 'Reporte 608', onTap: () {}),
            SidebarSubItem(title: 'Reporte 609', onTap: () {}),
            SidebarSubItem(title: 'Reportes DGII', onTap: () {}),
          ],
        ),

      // 9. REPORTES
      if (auth.hasPermission('ver_reportes') || isAdmin || isContador)
        SidebarItem(
          title: 'Reportes',
          icon: Icons.bar_chart_outlined,
          subItems: [
            SidebarSubItem(
              title: 'Ventas',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReporteVentasScreen()),
              ),
            ),
            SidebarSubItem(title: 'Compras', onTap: () {}),
            SidebarSubItem(title: 'Inventario', onTap: () {}),
            SidebarSubItem(title: 'Finanzas', onTap: () {}),
            SidebarSubItem(title: 'RRHH', onTap: () {}),
            SidebarSubItem(title: 'Contabilidad', onTap: () {}),
          ],
        ),

      // 10. ADMINISTRACION
      if (auth.hasPermission('gestionar_usuarios') || isAdmin)
        SidebarItem(
          title: 'Administración',
          icon: Icons.settings_outlined,
          subItems: [
            SidebarSubItem(title: 'Usuarios', onTap: () {}),
            SidebarSubItem(title: 'Roles', onTap: () {}),
            SidebarSubItem(title: 'Permisos', onTap: () {}),
            SidebarSubItem(title: 'Configuración', onTap: () {}),
            SidebarSubItem(title: 'Auditoría', onTap: () {}),
          ],
        ),
    ];
  }
}
