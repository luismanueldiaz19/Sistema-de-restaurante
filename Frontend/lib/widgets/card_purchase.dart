// // =============================
// // 🚀 WIDGET PERSONALIZADO DE FACTURA
// // =============================
// import 'package:flutter/material.dart';
// import 'package:serkasa/model/item_combustible.dart';
// import 'package:serkasa/palletes/app_colors.dart';
// import 'package:serkasa/utils/get_number_formate.dart';

// import '../model/compra_combustible.dart';

// class PurchaseCard extends StatelessWidget {
//   final CompraCombustible purchase;

//   const PurchaseCard({super.key, required this.purchase});

//   @override
//   Widget build(BuildContext context) {
//     final style = Theme.of(context).textTheme;
//     return Padding(
//       padding: const EdgeInsets.all(25.0),
//       child: CustomPaint(
//         painter: FacturaPainter(),
//         child: Container(
//           // width: 300,
//           // height: 300, // Ajustado para ser más cuadrado
//           alignment: Alignment.center,
//           padding: EdgeInsets.all(16),
//           child: Padding(
//             padding: EdgeInsets.all(15),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 🟢 ENCABEZADO DE LA FACTURA
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "#Compra : ${purchase.compraCombustibleId}",
//                             style: TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold),
//                           ),
//                           Tooltip(
//                             message:
//                                 'Referencia de Factura ${purchase.numeroFactura}',
//                             child: Text("#${purchase.numeroFactura}",
//                                 style: style.bodySmall
//                                     ?.copyWith(color: Colors.black45)),
//                           ),
//                           Text(
//                             purchase.proveedor ?? 'Proveedor',
//                             style: TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       purchase.fecha ?? 'N/A',
//                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//                 Divider(),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "Producto",
//                       style: TextStyle(color: AppColors.primary),
//                     ),
//                     Row(
//                       children: [
//                         Text(
//                           "Distribución A",
//                           style: TextStyle(color: AppColors.primary),
//                         ),
//                         const SizedBox(width: 10),
//                         Text(
//                           "Units",
//                           style: TextStyle(color: AppColors.primary),
//                         ),
//                         const SizedBox(width: 10),
//                         Text(
//                           "Precio",
//                           style: TextStyle(color: AppColors.primary),
//                         ),
//                         const SizedBox(width: 10),
//                         Text(
//                           "SubTotal",
//                           style: TextStyle(color: AppColors.primary),
//                         ),
//                       ],
//                     )
//                   ],
//                 ),
//                 // 🟢 LISTA DE ITEMS
//                 Column(
//                   children: purchase.items!.map((item) {
//                     return Padding(
//                       padding: EdgeInsets.symmetric(vertical: 4),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               item.tipoCombustible ?? "",
//                               style: TextStyle(fontSize: 14),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Text(
//                             item.nombreDivicion ?? "",
//                             style: TextStyle(fontSize: 14),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(width: 10),
//                           Text("${item.cantidad} x \$${item.precioPorCantidad}",
//                               style: TextStyle(fontSize: 14)),
//                           const SizedBox(width: 10),
//                           Text(
//                               "\$ ${getNumFormatedDouble(ItemCombustible.calcularSubtotal(item.cantidad, item.precioPorCantidad).toString())}",
//                               style: TextStyle(
//                                   fontSize: 14, fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//                 ),

//                 Divider(),

//                 // 🟢 TOTAL
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text("Total:",
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold)),
//                     Text(
//                         "\$ ${getNumFormatedDouble(ItemCombustible.getTotal(purchase.items!))}",
//                         style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.accent)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // =============================
// // 🎨 CUSTOM PAINTER PARA EL CORTE
// // =============================
// class FacturaPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()..color = Colors.white; // Color de la factura

//     Path path = Path();

//     double triangleSize = 10; // Tamaño del diente

//     // 🔵 Comenzamos desde la esquina superior izquierda
//     path.moveTo(0, 0);

//     // 🔽 Triángulos superiores
//     for (double i = 0; i < size.width; i += triangleSize * 2) {
//       path.lineTo(i + triangleSize, triangleSize);
//       path.lineTo(i + (triangleSize * 2), 0);
//     }

//     // 📏 Lado derecho
//     path.lineTo(size.width, size.height);

//     // 🔽 Triángulos inferiores
//     for (double i = size.width; i > 0; i -= triangleSize * 2) {
//       path.lineTo(i - triangleSize, size.height - triangleSize);
//       path.lineTo(i - (triangleSize * 2), size.height);
//     }

//     // 📏 Lado izquierdo
//     path.lineTo(0, 0);
//     path.close();

//     // 🖌️ Dibujar la forma
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
