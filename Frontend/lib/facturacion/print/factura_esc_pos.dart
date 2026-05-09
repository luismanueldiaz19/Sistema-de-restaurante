import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:sistema_restaurante/model/factura.dart';
import 'package:sistema_restaurante/utils/helpers.dart';

class FacturaEscPos {
  static Future<void> imprimirRed(
    Factura factura,
    String ip, {
    int port = 9100,
  }) async {
    try {
      // 1. Cargar perfil de la impresora
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      // 2. Intentar conexión
      final PosPrintResult result = await printer.connect(ip, port: port);

      if (result != PosPrintResult.success) {
        print(
          'ERROR: No se pudo conectar a la impresora en $ip:$port -> ${result.msg}',
        );
        return;
      }

      print('CONECTADO: Generando ticket para factura #${factura.id}...');

      // 3. Generar contenido del ticket
      printer.text(
        'SISTEMA RESTAURANTE',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      printer.text(
        'Calle Principal #123, RD',
        styles: const PosStyles(align: PosAlign.center),
      );
      printer.text(
        'RNC: 131-12345-6',
        styles: const PosStyles(align: PosAlign.center),
      );
      printer.text(
        'Tel: 809-555-5555',
        styles: const PosStyles(align: PosAlign.center),
      );
      printer.hr();

      printer.text(
        'FACTURA: ${factura.ncf ?? 'PROFORMA'}',
        styles: const PosStyles(bold: true),
      );
      printer.text(
        'FECHA: ${formatFechaHora(factura.fechaEmision ?? DateTime.now())}',
      );
      printer.text('CLIENTE: ${factura.cliente?.nombre ?? 'CLIENTE FINAL'}');
      printer.hr();

      // Detalles
      printer.row([
        PosColumn(text: 'DESC', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'CANT',
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
        PosColumn(
          text: 'TOTAL',
          width: 3,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
      printer.hr(ch: '-');

      for (var d in (factura.detalles ?? [])) {
        printer.row([
          PosColumn(text: d.descripcion ?? '', width: 7),
          PosColumn(
            text: '${d.cantidad}',
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: formatCurrency(d.total ?? 0.0),
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      printer.hr();

      // Helper para parsing seguro
      double parseSafe(String? val) => double.tryParse(val ?? '0') ?? 0.0;

      // Totales
      printer.row([
        PosColumn(text: 'SUBTOTAL:', width: 8),
        PosColumn(
          text: formatCurrency(parseSafe(factura.subtotal)),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      printer.row([
        PosColumn(text: 'ITBIS (18%):', width: 8),
        PosColumn(
          text: formatCurrency(parseSafe(factura.itbis)),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      double desc = parseSafe(factura.descuentoTotal);
      if (desc > 0) {
        printer.row([
          PosColumn(text: 'DESC.:', width: 8),
          PosColumn(
            text: '-${formatCurrency(desc)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      printer.row([
        PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
        PosColumn(
          text: formatCurrency(parseSafe(factura.total)),
          width: 6,
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            align: PosAlign.right,
          ),
        ),
      ]);

      printer.feed(2);
      printer.text(
        '*** GRACIAS POR SU COMPRA ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      printer.feed(1);
      printer.cut();

      // 4. Desconectar con un pequeño delay para asegurar el envío
      await Future.delayed(const Duration(milliseconds: 500));
      printer.disconnect();
      print('IMPRESIÓN COMPLETADA');
    } catch (e) {
      print('ERROR CRÍTICO EN IMPRESIÓN: $e');
    }
  }
}
