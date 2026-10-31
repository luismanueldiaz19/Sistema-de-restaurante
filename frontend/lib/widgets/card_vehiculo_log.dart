// import 'package:flutter/material.dart';
// import 'package:serkasa/model/vehiculo.dart';
// import 'package:serkasa/utils/helpers.dart';

// class CardVehiculoLog extends StatelessWidget {
//   const CardVehiculoLog({
//     super.key,
//     this.vehiculo,
//     required this.onRemove,
//   });

//   final Vehiculo? vehiculo;
//   final VoidCallback onRemove;

//   @override
//   Widget build(BuildContext context) {
//     final style = Theme.of(context).textTheme;
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: Row(
//         children: [
//           const CircleAvatar(
//             backgroundColor: Colors.blueGrey,
//             radius: 24,
//             child: Icon(Icons.local_shipping, color: Colors.white, size: 28),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   vehiculo?.ficha ?? 'Sin ficha',
//                   style: style.bodyMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.directions_car,
//                         size: 16, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Text(
//                       limitarTexto(vehiculo?.marca ?? 'Sin marca', 15),
//                       style: style.bodySmall?.copyWith(color: Colors.grey[700]),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       vehiculo?.placas ?? 'Sin placas',
//                       style: style.bodySmall?.copyWith(color: Colors.grey[700]),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 2),
//                 Row(
//                   children: [
//                     const Icon(Icons.settings, size: 16, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         vehiculo?.tipoCombustible ??
//                             'Combustible no registrado',
//                         style:
//                             style.bodySmall?.copyWith(color: Colors.grey[700]),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           // IconButton(
//           //   icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
//           //   onPressed: onRemove,
//           //   tooltip: 'Quitar vehículo',
//           // ),
//           IconButton(
//             icon: const Icon(Icons.swap_horiz, color: Colors.orangeAccent),
//             onPressed: onRemove,
//             tooltip: 'Cambiar vehículo',
//           ),
//         ],
//       ),
//     );
//   }
// }
