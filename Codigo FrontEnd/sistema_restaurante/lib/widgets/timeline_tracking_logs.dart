// import 'package:flutter/material.dart';

// import '../model/log_pedido.dart';

// class TimelineTrackingLogs extends StatelessWidget {
//   final List<LogPedido> logs;

//   const TimelineTrackingLogs({super.key, required this.logs});

//   @override
//   Widget build(BuildContext context) {
//     final reversedLogs =
//         logs.reversed.toList(); // Para mostrar el más reciente arriba
//     final lastIndex = reversedLogs.length - 1;

//     return ListView.builder(
//       itemCount: reversedLogs.length,
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       itemBuilder: (context, index) {
//         final log = reversedLogs[index];
//         final isUltimo = index == 0;

//         return Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Línea + icono
//             Column(
//               children: [
//                 Container(
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     color: isUltimo ? Colors.blue : Colors.grey.shade300,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     isUltimo ? Icons.check_circle : Icons.radio_button_checked,
//                     color: Colors.white,
//                     size: 16,
//                   ),
//                 ),
//                 if (index != lastIndex)
//                   Container(
//                     width: 2,
//                     height: 60,
//                     color: Colors.grey.shade300,
//                   ),
//               ],
//             ),
//             const SizedBox(width: 12),
//             // Información
//             Expanded(
//               child: Container(
//                 margin: const EdgeInsets.only(bottom: 20),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: isUltimo ? Colors.blue.shade50 : Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: isUltimo ? Colors.blue : Colors.grey.shade300,
//                     width: 1,
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '${log.tipoChequeo ?? ''} - ${log.usuario ?? ''}',
//                       style: TextStyle(
//                         fontWeight:
//                             isUltimo ? FontWeight.bold : FontWeight.normal,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       log.fecha ?? '',
//                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 4),
//                     if (log.observaciones != null &&
//                         log.observaciones!.isNotEmpty)
//                       Text(
//                         log.observaciones!,
//                         style: const TextStyle(fontSize: 13),
//                       ),
//                     // if (isUltimo)
//                     //   Padding(
//                     //     padding: const EdgeInsets.only(top: 6),
//                     //     child: Text(
//                     //       'Paso actual',
//                     //       style: TextStyle(
//                     //           fontSize: 12,
//                     //           color: Colors.blue,
//                     //           fontWeight: FontWeight.bold),
//                     //     ),
//                     //   )
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
