// import 'package:flutter/material.dart';
// import 'package:serkasa/model/tipo_services.dart';
// import 'package:serkasa/palletes/app_colors.dart';

// class CardServicios extends StatelessWidget {
//   const CardServicios({super.key, this.item, this.isTap = true});
//   final TipoServices? item;
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
//         leading: const Icon(Icons.tips_and_updates_outlined),
//         title: Tooltip(
//             message: item?.nombre ?? "Sin nombre",
//             child: Text(item?.nombre ?? "Sin nombre", style: style.bodySmall)),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Descripcion: ${item?.descripcion ?? "Sin nombre"}",
//                 style: style.bodySmall
//                     ?.copyWith(color: AppColors.textSecondary, fontSize: 10)),
//             Text("Categoria: ${item?.categoria ?? "Sin nombre"}",
//                 style: style.bodySmall
//                     ?.copyWith(color: AppColors.error, fontSize: 10)),
//           ],
//         ),
//         onTap: isTap ? () => Navigator.pop(context, item) : null,
//       ),
//     );
//   }
// }
