// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import '../../../model/factura.dart';
// import '../../../utils/helpers.dart';

// class FacturaTicket {
//   static Future<void> imprimir(Factura factura) async {
//     final pdf = pw.Document();

//     const ticketFormat = PdfPageFormat(
//       58 * PdfPageFormat.mm,
//       double.infinity,
//       marginAll: 2 * PdfPageFormat.mm,
//     );

//     pdf.addPage(
//       pw.Page(
//         pageFormat: ticketFormat,
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Header
//               pw.Center(
//                 child: pw.Text(
//                   'SISTEMA RESTAURANTE',
//                   style: pw.TextStyle(
//                     fontWeight: pw.FontWeight.bold,
//                     fontSize: 10,
//                   ),
//                 ),
//               ),
//               pw.Center(
//                 child: pw.Text(
//                   'Calle Principal #123, RD',
//                   style: const pw.TextStyle(fontSize: 7),
//                 ),
//               ),
//               pw.Center(
//                 child: pw.Text(
//                   'RNC: 131-12345-6',
//                   style: const pw.TextStyle(fontSize: 7),
//                 ),
//               ),
//               pw.Center(
//                 child: pw.Text(
//                   'Tel: 809-555-5555',
//                   style: const pw.TextStyle(fontSize: 7),
//                 ),
//               ),
//               pw.SizedBox(height: 5),
//               pw.Divider(thickness: 0.5),

//               // Factura Info
//               pw.Text(
//                 'FACTURA: ${factura.ncf ?? 'PROFORMA'}',
//                 style: pw.TextStyle(
//                   fontWeight: pw.FontWeight.bold,
//                   fontSize: 8,
//                 ),
//               ),
//               pw.Text(
//                 'FECHA: ${formatFechaHora(factura.fechaEmision ?? DateTime.now())}',
//                 style: const pw.TextStyle(fontSize: 7),
//               ),
//               pw.Text(
//                 'CLIENTE: ${factura.cliente?.nombre ?? 'CLIENTE FINAL'}',
//                 style: const pw.TextStyle(fontSize: 7),
//               ),
//               if (factura.cliente?.rncCedula != null)
//                 pw.Text(
//                   'RNC/CÉD: ${factura.cliente?.rncCedula}',
//                   style: const pw.TextStyle(fontSize: 7),
//                 ),
//               pw.SizedBox(height: 5),
//               pw.Divider(thickness: 0.5),

//               // Items Header
//               pw.Row(
//                 children: [
//                   pw.Expanded(
//                     child: pw.Text(
//                       'DESC',
//                       style: pw.TextStyle(
//                         fontWeight: pw.FontWeight.bold,
//                         fontSize: 7,
//                       ),
//                     ),
//                   ),
//                   pw.Text(
//                     'CANT',
//                     style: pw.TextStyle(
//                       fontWeight: pw.FontWeight.bold,
//                       fontSize: 7,
//                     ),
//                   ),
//                   pw.SizedBox(width: 5),
//                   pw.Text(
//                     'TOTAL',
//                     style: pw.TextStyle(
//                       fontWeight: pw.FontWeight.bold,
//                       fontSize: 7,
//                     ),
//                   ),
//                 ],
//               ),
//               pw.Divider(thickness: 0.2, borderStyle: pw.BorderStyle.dashed),

//               // Items List
//               ...(factura.detalles ?? []).map(
//                 (d) => pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(vertical: 1),
//                   child: pw.Row(
//                     children: [
//                       pw.Expanded(
//                         child: pw.Text(
//                           d.descripcion ?? '',
//                           style: const pw.TextStyle(fontSize: 7),
//                         ),
//                       ),
//                       pw.Text(
//                         '${d.cantidad}',
//                         style: const pw.TextStyle(fontSize: 7),
//                       ),
//                       pw.SizedBox(width: 5),
//                       pw.Text(
//                         formatCurrency(d.total ?? 0.0),
//                         style: const pw.TextStyle(fontSize: 7),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               pw.Divider(thickness: 0.5),

//               // Totals
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text('SUBTOTAL:', style: const pw.TextStyle(fontSize: 8)),
//                   pw.Text(
//                     formatCurrency(double.parse(factura.subtotal ?? '0')),
//                     style: const pw.TextStyle(fontSize: 8),
//                   ),
//                 ],
//               ),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text(
//                     'ITBIS (18%):',
//                     style: const pw.TextStyle(fontSize: 8),
//                   ),
//                   pw.Text(
//                     formatCurrency(double.parse(factura.itbis ?? '0')),
//                     style: const pw.TextStyle(fontSize: 8),
//                   ),
//                 ],
//               ),
//               if (double.parse(factura.descuentoTotal ?? '0') > 0)
//                 pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Text('DESC.:', style: const pw.TextStyle(fontSize: 8)),
//                     pw.Text(
//                       '-${formatCurrency(double.parse(factura.descuentoTotal ?? '0'))}',
//                       style: const pw.TextStyle(fontSize: 8),
//                     ),
//                   ],
//                 ),
//               pw.SizedBox(height: 2),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text(
//                     'TOTAL:',
//                     style: pw.TextStyle(
//                       fontWeight: pw.FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                   ),
//                   pw.Text(
//                     formatCurrency(double.parse(factura.total ?? '0')),
//                     style: pw.TextStyle(
//                       fontWeight: pw.FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ],
//               ),

//               pw.SizedBox(height: 10),
//               pw.Center(
//                 child: pw.Text(
//                   '*** GRACIAS POR SU COMPRA ***',
//                   style: pw.TextStyle(
//                     fontSize: 7,
//                     fontStyle: pw.FontStyle.italic,
//                   ),
//                 ),
//               ),
//               pw.SizedBox(height: 5),
//             ],
//           );
//         },
//       ),
//     );

//     // Direct printing dialog
//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//       format: ticketFormat, // <--- FORZAR EL FORMATO AQUÍ TAMBIÉN
//       name: 'Ticket_${factura.id}',
//     );
//   }
// }
