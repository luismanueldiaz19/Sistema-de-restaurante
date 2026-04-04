import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sistema_restaurante/facturacion/screens/add_factura.dart';
import 'package:sistema_restaurante/modulo_cliente/screens/screen_client_admin.dart';
import 'package:sistema_restaurante/utils/constants.dart';
import 'package:sistema_restaurante/widgets/menu_drop.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/permission_helper.dart';
import '../widgets/permission_widget.dart';
import 'dashboard_buttons_section/dashboard_buttons_section.dart';
import 'header_facturacion/header_facturacion.dart';
import 'ventas_dia_banner/resumen_card.dart';
import 'ventas_dia_banner/ultimas_ventas.dart';
import 'ventas_dia_banner/ventas_dia_banner.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // final auth = AuthService();

  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final List<VentaItem> listaVentas = [
      VentaItem(
        factura: '#00563',
        cliente: 'José Martínez',
        total: 5800.00,
        estado: 'Pagada',
      ),
      VentaItem(
        factura: '#00562',
        cliente: 'María Gómez',
        total: 12300.00,
        estado: 'Pendiente',
      ),
      VentaItem(
        factura: '#00561',
        cliente: 'Cliente Genérico',
        total: 7200.00,
        estado: 'Pagada',
      ),
      VentaItem(
        factura: '#00560',
        cliente: 'Carlos Pérez',
        total: 10400.00,
        estado: 'Pagada',
      ),
    ];
    if (!auth.isAuthenticated) {
      return Scaffold(body: Center(child: Text("No hay sesión")));
    }
    return Scaffold(
      endDrawer: Menudrop(),
      key: scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: HeaderFacturacion(
          nombreSistema: 'Sistema Lwader Soft',
          montoCaja: 12500.00,
          cajaAbierta: true,
          usuario: auth.user!.name!,
          fecha: DateTime.now(),
          onMenuTap: () {
            scaffoldKey.currentState?.openEndDrawer();
          },
        ),
      ),
      body: Column(
        children: [
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     spacing: 10,
          //     children: [
          //       PermissionWidget(
          //         permissions: auth.permissions,
          //         permiso: "editar_clientes",
          //         child: ElevatedButton(
          //           onPressed: () {},
          //           child: Text("Editar Clientes"),
          //         ),
          //       ),
          //       PermissionWidget(
          //         permissions: auth.permissions,
          //         permiso: "crear_clientes",
          //         child: ElevatedButton(
          //           onPressed: () {},
          //           child: Text("Crear Cliente"),
          //         ),
          //       ),
          //       PermissionWidget(
          //         permissions: auth.permissions,
          //         permiso: "eliminar_clientes",
          //         child: ElevatedButton(
          //           onPressed: () {},
          //           child: Text("Borrar Cliente"),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          DashboardButtonsSection(
            onAction: (action) {
              switch (action) {
                case 'venta':
                  // print('Ir a Nueva Venta');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CrearFacturaPage()),
                  );
                  break;
                case 'clientes':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenClientAdmin(),
                    ),
                  );
                  break;
              }
            },
          ),
          // VentasDiaBanner(totalFacturas: 15, totalVentas: 5258895),
          // const SizedBox(height: 16),
          // Expanded(child: UltimasVentasTable(ventas: listaVentas)),
          // const SizedBox(height: 16),
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: Row(
          //     children: const [
          //       ResumenCard(
          //         icon: Icons.receipt,
          //         titulo: 'Factura del Día',
          //         valor: '#00563',
          //         color: Colors.blue,
          //       ),
          //       SizedBox(width: 12),
          //       ResumenCard(
          //         icon: Icons.warning,
          //         titulo: 'Stock Bajo',
          //         valor: '4 Productos',
          //         color: Colors.orange,
          //       ),
          //       SizedBox(width: 12),
          //       ResumenCard(
          //         icon: Icons.people,
          //         titulo: 'Clientes Activos',
          //         valor: '2250',
          //         color: Colors.green,
          //       ),
          //       SizedBox(width: 12),
          //       ResumenCard(
          //         icon: Icons.notifications,
          //         titulo: 'Notificaciones',
          //         valor: '2 Pendientes',
          //         color: Colors.red,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
