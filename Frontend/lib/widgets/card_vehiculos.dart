// import 'package:flutter/material.dart';
// import 'package:serkasa/model/seguro.dart';
// import 'package:serkasa/model/vehiculo.dart';
// import 'package:serkasa/palletes/app_colors.dart';
// import 'package:serkasa/screens/reportes_incidencias/add_reporte_incidencia.dart';
// import 'package:serkasa/screens/reportes_incidencias/screen_incidencia_by_ficha.dart';
// import 'package:serkasa/screens/visitas/ver_visitas_vehiculos.dart';
// import 'package:serkasa/utils/constants.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:serkasa/utils/helpers.dart';
// import '../model/vehiculo_asignado.dart';
// import '../screens/choferes/screen_view_card_seguro.dart';
// import '../screens/mantenimientos/add_mantenimiento.dart';
// import '../screens/reportes_vehiculos/add_reporte_visitas.dart';
// import '../screens/vehiculos/add_poliza_seguro.dart';

// class VehiculoCard extends StatelessWidget {
//   final VehiculoAsignado vehiculoAsignado;

//   const VehiculoCard({super.key, required this.vehiculoAsignado});

//   @override
//   Widget build(BuildContext context) {
//     Vehiculo? data = vehiculoAsignado.vehiculo;
//     Seguro? seguro = vehiculoAsignado.seguro;

//     final urlImage = 'http://$ipLocal/$pathHost/imagen_vehiculo';
//     final style = Theme.of(context).textTheme;
//     return data != null
//         ? Card(
//             elevation: 4,
//             margin: const EdgeInsets.all(12),
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
//             color: Colors.white,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Imagen principal
//                 ClipRRect(
//                   borderRadius:
//                       const BorderRadius.vertical(top: Radius.circular(0)),
//                   child: data.imagenPath != "N/A"
//                       ? Image.network(
//                           '$urlImage/${data.imagenPath!}',
//                           height: 160,
//                           width: double.infinity,
//                           fit: BoxFit.cover,
//                         )
//                       : Container(
//                           height: 160,
//                           width: double.infinity,
//                           color: Colors.grey[300],
//                           child: const Icon(Icons.directions_car_filled,
//                               size: 80, color: Colors.grey),
//                         ),
//                 ),
//                 Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               data.marca ?? 'N/A',
//                               style: const TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           Text(
//                             data.year ?? '',
//                             style: const TextStyle(
//                                 fontSize: 16, color: Colors.grey),
//                           ),
//                           // _EstadoChip(estado: data.status ?? 'N/A'),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       // Placa
//                       Text(
//                         'Placa: ${data.placas}',
//                         style: const TextStyle(
//                             fontSize: 14, color: Colors.black87),
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text('${data.ultimaCarga ?? 'N/A'} Galones',
//                               style: const TextStyle(
//                                   fontSize: 14, color: AppColors.error)),
//                           Text(
//                             data.ultimaCargaFecha ?? '',
//                             style: const TextStyle(
//                                 fontSize: 14, color: Colors.black87),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       // Línea de info con íconos
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           TextButton(
//                               onPressed: seguro != null
//                                   ? () => _showSeguroDialog(context)
//                                   : null,
//                               child: buildSeguroBadge(data.estadoSeguro ?? '')),
//                           _InfoIcon(
//                               icon: LucideIcons.glassWater,
//                               label: data.tipoCombustible ?? ''),
//                           _InfoIcon(
//                               icon: LucideIcons.fileBadge,
//                               label: data.ficha ?? 'Sin Ficha'),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       const Divider(),
//                       // Estado y botones
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           CustomTextIconButton(
//                             width: 120,
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) =>
//                                         AddIncidenciaPage(vehiculos: data)),
//                               );
//                             },
//                             icon: Icons.report_gmailerrorred,
//                             text: "Reportar",
//                             colorButton: AppColors.primary,
//                           ),
//                           Row(
//                             children: [
//                               Tooltip(
//                                 message: 'Publicar Visita',
//                                 child: IconButton(
//                                   icon: const Icon(
//                                       Icons.add_circle_outline_sharp,
//                                       color: Colors.black54),
//                                   onPressed: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             AddReporteVisitas(vehiculo: data),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                               Tooltip(
//                                 message: 'Reportar Mantenimiento',
//                                 child: IconButton(
//                                   icon: const Icon(Icons.plumbing_outlined,
//                                       color: Colors.black54),
//                                   onPressed: () {
//                                     Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                             builder: (_) => AddMantenimiento(
//                                                 vehiculo: data)));
//                                   },
//                                 ),
//                               ),
//                               buildMenuAcciones(context, data)
//                             ],
//                           ),
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           )
//         : SizedBox.shrink();
//   }

//   void _showSeguroDialog(context) async {
//     showDialog(
//       context: context,
//       builder: (context) =>
//           ScreenViewCardSeguro(seguro: vehiculoAsignado.seguro!),
//     );
//   }
// }

// // Componente para mostrar íconos con texto
// class _InfoIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _InfoIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: Colors.grey[700]),
//         const SizedBox(width: 4),
//         Text(label, style: const TextStyle(fontSize: 14)),
//       ],
//     );
//   }
// }

// Widget buildMenuAcciones(BuildContext context, dynamic vehiculo) {
//   return PopupMenuButton<int>(
//     tooltip: "Acciones",
//     elevation: 6,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     icon: const Icon(Icons.more_vert, size: 25, color: Colors.black54),
//     onSelected: (value) {
//       switch (value) {
//         case 1:
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => VerVisitasVehiculos(vehiculo: vehiculo),
//             ),
//           );
//           break;
//         case 2:
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => SeguroVehiculoForm(vehiculo: vehiculo),
//             ),
//           );
//           break;
//         case 3:
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => ScreenIncidenciaByFicha(vehiculo: vehiculo),
//             ),
//           );
//           break;
//       }
//     },
//     itemBuilder: (context) => [
//       PopupMenuItem(
//         value: 1,
//         child: Row(
//           children: const [
//             Icon(Icons.location_on_outlined, size: 20),
//             SizedBox(width: 10),
//             Text("Viajes"),
//           ],
//         ),
//       ),
//       PopupMenuItem(
//         value: 2,
//         child: Row(
//           children: const [
//             Icon(Icons.security_outlined, size: 20),
//             SizedBox(width: 10),
//             Text("Registrar Seguro"),
//           ],
//         ),
//       ),
//       PopupMenuItem(
//         value: 4,
//         child: Row(
//           children: const [
//             Icon(Icons.list_alt_outlined, size: 20),
//             SizedBox(width: 10),
//             Text("Ver Mantenimientos"),
//           ],
//         ),
//       ),
//       const PopupMenuDivider(),
//       PopupMenuItem(
//         value: 3,
//         child: Row(
//           children: const [
//             Icon(Icons.receipt_long, size: 20),
//             SizedBox(width: 10),
//             Text("Mis Reportes"),
//           ],
//         ),
//       ),
//     ],
//   );
// }
