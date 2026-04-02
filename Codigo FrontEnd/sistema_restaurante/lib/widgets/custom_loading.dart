// import 'package:animate_do/animate_do.dart';
// import 'package:flutter/material.dart';

// class CustomLoading extends StatelessWidget {
//   const CustomLoading(
//       {super.key,
//       this.imagen = 'assets/logo_serkasa.png',
//       this.text = 'No hay datos',
//       this.scale = 5});
//   final String text;
//   final String imagen;
//   final double? scale;

//   @override
//   Widget build(BuildContext context) {
//     final style = Theme.of(context).textTheme;
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Bounce(
//               curve: Curves.elasticInOut,
//               child: Image.asset(imagen, scale: scale ?? 5.0)),
//           Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text(text, style: style.bodySmall))
//         ],
//       ),
//     );
//   }
// }
