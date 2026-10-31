// import 'package:flutter/material.dart';

// import '../utils/get_number_formate.dart';

// class CreditCardWidget extends StatelessWidget {
//   final String tipoCuenta;
//   final String cardNumber;
//   final String balance;
//   final Color color;

//   const CreditCardWidget({
//     super.key,
//     required this.tipoCuenta,
//     required this.cardNumber,
//     required this.balance,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final style = Theme.of(context).textTheme;
//     return Container(
//       margin: const EdgeInsets.only(right: 1),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4)),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//               child: Text(tipoCuenta.toUpperCase(),
//                   style: style.titleMedium?.copyWith(
//                       color: Colors.white, fontWeight: FontWeight.bold))),
//           // const SizedBox(height: 5),
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('\$', style: const TextStyle(color: Colors.white)),
//                 Text(getNumFormatedDouble(balance),
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Text('Account : $cardNumber',
//                     style: style.bodySmall?.copyWith(color: Colors.white))
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
