// import 'package:flutter/material.dart';
// import 'package:serkasa/model/proveedor.dart';
// import 'package:serkasa/palletes/app_colors.dart';

// class CardProveedor extends StatelessWidget {
//   const CardProveedor({super.key, this.item, this.isTap = true});
//   final Proveedor? item;
//   final bool isTap;

//   @override
//   Widget build(BuildContext context) {
//     final style = Theme.of(context).textTheme;
//     return Container(
//       padding: EdgeInsets.all(5),
//       margin: EdgeInsets.all(5),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 6,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ListTile(
//         leading: const Icon(Icons.co_present_outlined),
//         title: Tooltip(
//             message: item?.nombreProveedor ?? "Sin nombre",
//             child: Text(item?.nombreProveedor ?? "Sin nombre",
//                 style: style.bodySmall)),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Dirrección: ${item?.direccion ?? "Sin nombre"}",
//                 style: style.bodySmall
//                     ?.copyWith(color: AppColors.textSecondary, fontSize: 10)),
//             Text("RNC: ${item?.rnc ?? "Sin nombre"}",
//                 style: style.bodySmall
//                     ?.copyWith(color: AppColors.error, fontSize: 10)),
//             Text('Correo: ${item?.correo ?? "Sin nombre"}',
//                 style: style.bodySmall
//                     ?.copyWith(color: AppColors.textSecondary, fontSize: 10)),
//             Text('Tel: ${item?.telefono ?? "Sin nombre"}',
//                 style: style.bodySmall
//                     ?.copyWith(color: AppColors.primary, fontSize: 10)),
//             Text(item?.tipoProveedor ?? "Sin nombre",
//                 style: style.bodySmall
//                     ?.copyWith(color: AppColors.textSecondary, fontSize: 10))
//           ],
//         ),
//         onTap: isTap ? () => Navigator.pop(context, item) : null,
//       ),
//     );
//   }
// }
