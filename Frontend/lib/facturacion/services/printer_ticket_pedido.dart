import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:intl/intl.dart';

import '../../model/company.dart';
import '../../pedidos/models/pedido.dart';
import '../../facturacion/services/printer_service.dart';

class PedidoPrinterService {
  PedidoPrinterService._();
  static final instance = PedidoPrinterService._();

  Future<ResultadoImpresora> imprimirPedido(
    Pedido pedido, {
    Printer? printer,
    bool esCopia = false,
  }) async {
    try {
      final nombreLimpio = _limpiarTexto(Company.current.nombre.toUpperCase());
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 2);
      List<int> bytes = [];

      bytes += generator.reset();
      bytes += generator.emptyLines(1);

      if (esCopia) {
        bytes += generator.text(
          '*** COPIA ***',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );
        bytes += generator.emptyLines(1);
      }

      bytes += generator.text(
        nombreLimpio,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      bytes += generator.text(
        'TICKET DE PEDIDO',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      bytes += generator.emptyLines(1);

      bytes += generator.text(
        'Pedido No. : ${pedido.secuenciaDiaria}',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.text(
        'Fecha      : ${pedido.fecha}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'Estado     : ${pedido.estado}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'Entrega    : ${pedido.tipoEntrega}',
        styles: const PosStyles(align: PosAlign.left),
      );

      bytes += generator.hr(ch: '-');
      bytes += generator.text(
        'Cliente    : ${_limpiarTexto(pedido.clienteNombre)}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'Telefono   : ${pedido.clienteTelefono ?? 'N/A'}',
        styles: const PosStyles(align: PosAlign.left),
      );
      if (pedido.direccion != null && pedido.direccion!.isNotEmpty) {
        bytes += generator.text(
          'Direccion  : ${_limpiarTexto(pedido.direccion!)}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      if (pedido.nota != null && pedido.nota!.isNotEmpty) {
        bytes += generator.hr(ch: '-');
        bytes += generator.text(
          'NOTA:',
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
        bytes += generator.text(
          _limpiarTexto(pedido.nota!),
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      bytes += generator.emptyLines(1);
      bytes += generator.hr(ch: '=');

      String buildRow(String c1, String c2, String c3, String c4) {
        return c1.padRight(21) +
            c2.padLeft(4) +
            c3.padLeft(10) +
            c4.padLeft(13);
      }

      bytes += generator.text(
        buildRow('Descripcion', 'Cant', 'P.Unit', 'P.Total'),
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.hr(ch: '-');

      final formatter = NumberFormat('#,##0.00', 'en_US');
      for (final item in pedido.detalles) {
        String desc = _truncate(_limpiarTexto(item.nombreProducto), 20);
        String cant = _fmtCant(item.cantidad);
        String pUnit = formatter.format(item.precioUnitario);
        String pTot = formatter.format(item.cantidad * item.precioUnitario);
        bytes += generator.text(
          buildRow(desc, cant, pUnit, pTot),
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      bytes += generator.hr(ch: '=');
      bytes += generator.text(
        'Total: '.padLeft(30) + _fmtMoneda(pedido.total).padLeft(18),
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
          height: PosTextSize.size2,
        ),
      );

      bytes += generator.emptyLines(1);

      if (pedido.codigoBarras != null && pedido.codigoBarras!.isNotEmpty) {
        bytes += generator.emptyLines(1);

        // Número de pedido gigante
        bytes += generator.text(
          'PEDIDO #${pedido.secuenciaDiaria}',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          ),
        );

        bytes += generator.emptyLines(1);

        bytes += generator.text(
          'ESCANEE PARA FACTURAR',
          styles: const PosStyles(align: PosAlign.center),
        );

        bytes += generator.emptyLines(1);

        // Imprimir el EAN13
        // La impresora automáticamente añade los números debajo del código en el formato estándar
        final barData = pedido.codigoBarras!
            .split('')
            .map((e) => int.parse(e))
            .toList();

        bytes += generator.barcode(
          Barcode.ean13(barData),
          width: 3, // Hace el código de barras más ancho
          height: 120, // Hace las barras más altas
          font:
              BarcodeFont.fontB, // Usa una fuente más pequeña para los números
        );
      }

      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      return await ThermalPrinterService.instance.printBytes(
        bytes,
        printer: printer,
      );
    } catch (e) {
      return ResultadoImpresora(
        exito: false,
        mensaje: 'Error al imprimir pedido: $e',
      );
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ─────────────────────────────────────────────

  String _fmtMoneda(double v) => 'RD\$ ${v.toStringAsFixed(2)}';

  String _fmtCant(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max - 2)}..' : s;

  String _limpiarTexto(String text) {
    if (text.isEmpty) return text;
    const conAcento = 'ÁÉÍÓÚáéíóúÑñ';
    const sinAcento = 'AEIOUaeiouNn';
    String res = text;
    for (int i = 0; i < conAcento.length; i++) {
      res = res.replaceAll(conAcento[i], sinAcento[i]);
    }
    return res;
  }
}
