// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/cliente_provider.dart';
// import '../widgets/cliente_table.dart';
// import '../widgets/cliente_search.dart';
// import '../models/cliente.dart';

// Future<Cliente?> showClienteModal(BuildContext context) {
//   // 🔥 FETCH AUTOMÁTICO AL ABRIR
//   Future.microtask(() {
//     // Provider.of<ClienteProvider>(context, listen: false).buscarClientes('');
//   });

//   return showDialog<Cliente>(
//     context: context,
//     builder: (context) {
//       return Dialog(
//         child: SizedBox(
//           width: 800,
//           height: 500,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 ClienteSearch(
//                   onChanged: (value) {
//                     // Provider.of<ClienteProvider>(context, listen: false)
//                     //     .buscarClientes(value);
//                   },
//                 ),
//                 const SizedBox(height: 10),
//                 Consumer<ClienteProvider>(
//                   builder: (_, provider, __) {
//                     if (provider.isLoading) {
//                       return const CircularProgressIndicator();
//                     }
//                     return ClienteTable(
//                       clientes: provider.clientes,
//                       onSelect: (c) {
//                         Navigator.pop(context, c);
//                       },
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }
