// import 'package:factu_me/model/usuario.dart';
import 'package:flutter/material.dart';
// import 'package:sistema_restaurante/model/user.dart';

// import '../model/empresa_local.dart';

const String appName = 'Tejidos Tropical';

// User? currentUsuario;

const String logoApp = 'assets/logo.jpeg';
// const ipLocal = '23.231.65.39';
///  otra ip :  104.206.57.61

// const ipLocal = '104.206.57.61';
//92.168.1.102
// const ipLocal = '192.168.100.7:8000';

const ipLocal = '192.168.100.7:8000';

const pathHost = 'lwader/backend/';
//const pathHost = 'ultimate_php/backend/';

const String logoSinFondo = 'assets/logo_sin_fondo.png';
// const String vertical = "imagen/vertical.png";
const double kwidth = 250;

String firmaLu = 'assets/logo_lwader.png';

String developerFirma = 'Lwader-Soft';

String textConfirmacion = '👉🏼Esta seguro realizar el pedido ? 👈🏼';
String textConfAction = '👉🏼Esta seguro realizar la acción ? 👈🏼';
String eliminarMjs = '🥺Esta seguro de eliminar🥺';
// String ActionMjs = '👉🏼Esta seguro de confirmar el tiempo ?👈🏼';
String confirmarMjs =
    '👉🏼Esta seguro de confirmar el despacho de las facturas?👈🏼';

String actionMjs = '👉🏼Esta seguro de confirmar el tiempo ?👈🏼';

// EmpresaLocal currentEmpresa = EmpresaLocal(
//   adressEmpressa:
//       'C. Beller #78, Puerto Plata 57000, Puerto Plata, República Dominicana',
//   celularEmpresa: '809-291-6505/ 829-421-8550',
//   nombreEmpresa: 'Tejidos Tropical',
//   oficinaEmpres: '809-291-6505/ 829-421-8550',
//   rncEmpresa: '037-0029474-1',
//   telefonoEmpresa: '809-291-6505/ 829-421-8550',
//   nCFEmpresa: '037-0029474-1',
//   correoEmpresa: 'Tejidostropical@gmail.com',
// );

final List<String> estadoHojaList = [
  'PENDIENTE'.toUpperCase(),
  'EN PROCESO'.toUpperCase(),
  'EN PRODUCCION'.toUpperCase(),
  'PAUSADO'.toUpperCase(),
  'COMPLETADO'.toUpperCase(),
  'CANCELADO'.toUpperCase(),
  'NORMAL'.toUpperCase(),
];
final Map<String?, Color> estadoHojaColores = {
  'PENDIENTE'.toUpperCase(): Colors.orange,
  'EN PROCESO'.toUpperCase(): Colors.blue,
  'EN PRODUCCION'.toUpperCase(): Colors.indigo,
  'PAUSADO'.toUpperCase(): Colors.grey,
  'COMPLETADO'.toUpperCase(): Colors.green,
  'CANCELADO'.toUpperCase(): Colors.red,
  'NORMAL'.toUpperCase(): Colors.white,
};
List<String>? priorityList = ['NORMAL', 'EMERGENCIA', 'PRIORIDAD', 'AGREGADO'];

Map<String, Color> priorityColors = {
  'NORMAL': Colors.white, // Cliente: NORMAL
  'EMERGENCIA': Colors.red.shade400, // Cliente: EMERGENCIA
  'PRIORIDAD': Colors.orange, // Cliente: PRIORIDAD
  'AGREGADO': Colors.yellow.shade300, // Cliente: AGREGADO,
};

Map<String, IconData> priorityIcons = {
  'NORMAL': Icons.check_circle_outline,
  'EMERGENCIA': Icons.warning_amber_rounded,
  'PRIORIDAD': Icons.priority_high,
  'AGREGADO': Icons.add_circle_outline,
};
Color getColorPriority(String priorityName) {
  return priorityColors[priorityName] ??
      Colors.white; // Retorna gris si no coincide con ninguna prioridad
}

String getClientePorPrioridad(String prioridad) {
  switch (prioridad) {
    case 'Normal':
      return 'Normal';
    case 'Hoja verde':
      return 'Emergencia';
    case 'Hoja naranja':
      return 'Prioridad';
    case 'Hoja amarilla':
      return 'Agregado';
    default:
      return 'Normal'; // En caso de que no coincida con ninguna prioridad
  }
}
