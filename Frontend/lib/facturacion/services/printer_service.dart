import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import '../../model/company.dart';

/// Resultado de operaciones de impresión
class ResultadoImpresora {
  final bool exito;
  final String mensaje;
  const ResultadoImpresora({required this.exito, required this.mensaje});
}

/// Ítem individual para el ticket
class ItemFactura {
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  double get total => cantidad * precioUnitario;

  const ItemFactura({
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
  });
}

/// Servicio singleton para impresión térmica USB
class ThermalPrinterService {
  ThermalPrinterService._();
  static final ThermalPrinterService instance = ThermalPrinterService._();

  final _plugin = FlutterThermalPrinter.instance;
  Printer? _printerConectado;

  // ─────────────────────────────────────────────
  // BUSCAR IMPRESORA USB (sin conectar — Windows no lo necesita)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> conectarAutomaticamente() async {
    try {
      final List<Printer> encontradas = [];

      _plugin.getPrinters(
        refreshDuration: const Duration(seconds: 3),
        connectionTypes: [ConnectionType.USB],
      );

      // Escuchar el stream durante 3 s
      final sub = _plugin.devicesStream.listen((printers) {
        for (final p in printers) {
          if (p.connectionType == ConnectionType.USB &&
              !encontradas.any((e) => e.address == p.address)) {
            encontradas.add(p);
          }
        }
      });

      await Future.delayed(const Duration(milliseconds: 3200));
      await sub.cancel();

      if (encontradas.isEmpty) {
        return const ResultadoImpresora(
          exito: false,
          mensaje: 'No se encontró ninguna impresora USB conectada.',
        );
      }

      // ⚠️ En Windows, USB NO necesita connect() — causa 'Read buffer fail'.
      // Solo guardamos la referencia; printData() accede directo al driver.
      _printerConectado = encontradas.first;

      return ResultadoImpresora(
        exito: true,
        mensaje:
            'Impresora lista: '
            '${_printerConectado!.name ?? _printerConectado!.address ?? 'USB'}',
      );
    } catch (e) {
      return ResultadoImpresora(
        exito: false,
        mensaje: 'Error al buscar impresora: $e',
      );
    }
  }

  // ─────────────────────────────────────────────
  // TEST: HOLA MUNDO  (verifica que la impresora funciona)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirPrueba() async {
    try {
      // Si no hay impresora guardada, buscar una primero
      if (_printerConectado == null) {
        final conexion = await conectarAutomaticamente();
        if (!conexion.exito) return conexion;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text('--------------------------------');
      bytes += generator.text(
        'HOLA MUNDO',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'Impresora OK',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text('Sistema: ${SystemInfo.systemName}');
      bytes += generator.text('Dev: ${SystemInfo.developerName}');
      bytes += generator.text('--------------------------------');
      bytes += generator.feed(2);
      bytes += generator.cut();

      await _plugin.printData(_printerConectado!, bytes, longData: true);

      return const ResultadoImpresora(
        exito: true,
        mensaje: '✓ Impresora funcionando correctamente.',
      );
    } catch (e) {
      return ResultadoImpresora(exito: false, mensaje: 'Error en prueba: $e');
    }
  }

  // ─────────────────────────────────────────────
  // IMPRIMIR FACTURA
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirFactura({
    required String nombreNegocio,
    required String direccion,
    required String rncOCedula,
    required String numeroFactura,
    required DateTime fecha,
    required List<ItemFactura> items,
    required double subtotal,
    required double impuesto,
    required double descuento,
    required double total,
    String? cliente,
    String? rncCliente,
    String? nota,
    String? tipoPago,
    String? metodoPago, // ej: 'EFECTIVO', 'TARJETA'
    double? montoRecibido, // monto que entregó el cliente
    double? devuelta, // cambio devuelto
    Printer? printer,
  }) async {
    try {
      Printer? target = printer ?? _printerConectado;

      if (target == null) {
        // Intentar conectar automáticamente si no hay impresora
        final conexion = await conectarAutomaticamente();
        if (!conexion.exito) {
          return ResultadoImpresora(
            exito: false,
            mensaje: 'Sin impresora conectada. ${conexion.mensaje}',
          );
        }
        target = _printerConectado!;
      }

      final nombreLimpio = _limpiarTexto(nombreNegocio.toUpperCase());
      final direccionLimpia = _limpiarTexto(direccion);
      final clienteLimpio = _limpiarTexto(cliente ?? "Consumidor Final");

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 2);
      List<int> bytes = [];

      // Reiniciar impresora
      bytes += generator.reset();

      // ── ENCABEZADO (Centrado) ──────
      bytes += generator.text(
        nombreLimpio,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        direccionLimpia,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Tel.: 809-000-0000',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'PRINCIPAL - SANTIAGO',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'RNC: $rncOCedula',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(1);

      // ── INFO FACTURA (Izquierda) ──────
      bytes += generator.text(
        'Fecha: ${_formatFecha(fecha)}',
        styles: const PosStyles(align: PosAlign.left),
      );

      String tipoDoc = (rncCliente != null && rncCliente.length == 9)
          ? 'Factura de Credito Fiscal'
          : 'Factura de Consumo Electronica';

      bytes += generator.text(
        tipoDoc,
        styles: const PosStyles(align: PosAlign.left),
      );

      bytes += generator.text(
        'e-NCF $numeroFactura',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.text(
        'Factura No. : $numeroFactura',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'RNC Cliente : ${rncCliente ?? ""}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'Cliente     : $clienteLimpio',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'FACTURA DE $tipoPago',
        styles: const PosStyles(align: PosAlign.left),
      );

      if (nota != null && nota.isNotEmpty) {
        bytes += generator.text(
          'Nota        : $nota',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      // ── ENCABEZADO DE ITEMS ───────────────────────
      bytes += generator.hr(ch: '=');

      // DESCRIPCION (21) | CANT (4) | P.UNIT (10) | P.TOTAL (13) = 48
      String buildRow(String c1, String c2, String c3, String c4) {
        return c1.padRight(21) +
            c2.padLeft(4) +
            c3.padLeft(10) +
            c4.padLeft(13);
      }

      bytes += generator.text(
        buildRow('Descripcion', 'Cant', 'P.Unit', 'P.Total'),
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.hr(ch: '=');

      // ── ITEMS ─────────────────────────────────────
      for (final item in items) {
        // Truncamos la descripción para que todo quepa en una sola línea
        String desc = _truncate(_limpiarTexto(item.descripcion), 20);
        String cant = _fmtCant(item.cantidad);
        String pUnit = item.precioUnitario.toStringAsFixed(2);
        String pTot = (item.cantidad * item.precioUnitario).toStringAsFixed(2);

        bytes += generator.text(
          buildRow(desc, cant, pUnit, pTot),
          styles: const PosStyles(align: PosAlign.left),
        );
      }
      bytes += generator.hr(ch: '=');

      // ── TOTALES ───────────────────────────────────
      String buildTotalRow(String label, String value) {
        // Total 48 chars (30 left padding para el label, 18 para el valor)
        return label.padLeft(30) + value.padLeft(18);
      }

      bytes += generator.text(
        buildTotalRow('Subtotal', _fmtMoneda(subtotal)),
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        buildTotalRow('ITBIS', _fmtMoneda(impuesto)),
        styles: const PosStyles(align: PosAlign.left),
      );

      if (descuento > 0) {
        bytes += generator.text(
          buildTotalRow('Descuento', '-${_fmtMoneda(descuento)}'),
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      // El total principal en texto grande (máximo 24 caracteres por el doble ancho)
      String buildTotalBig(String label, String value) {
        return label.padLeft(10) + value.padLeft(14);
      }

      bytes += generator.text(
        buildTotalBig('Total', _fmtMoneda(total)),
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.hr(ch: '=');

      if (metodoPago != null || montoRecibido != null) {
        if (metodoPago != null && montoRecibido != null) {
          bytes += generator.text(
            buildTotalRow(metodoPago.toUpperCase(), _fmtMoneda(montoRecibido)),
            styles: const PosStyles(align: PosAlign.left),
          );
        }
        if (devuelta != null && devuelta > 0) {
          bytes += generator.text(
            buildTotalRow('Cambio', _fmtMoneda(devuelta)),
            styles: const PosStyles(align: PosAlign.left),
          );
        }
        bytes += generator.hr(ch: '=');
      }

      // ── FIRMA ELECTRÓNICA / QR ─────────
      bytes += generator.emptyLines(1);
      String firmaSimulada =
          'https://dgii.gov.do/ecf/consultar?ncf=$numeroFactura&rnc=$rncOCedula';
      bytes += generator.qrcode(firmaSimulada);

      bytes += generator.text(
        'Codigo de seguridad: UVHpz',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Fecha de Firma Digital: ${_formatFecha(fecha)}',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'Revise su orden antes de retirarse. Para cualquier reclamo es indispensable presentar esta factura. No se devuelve efectivo.',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(1);

      // ── CRÉDITO DEL SISTEMA ───────────────────────
      bytes += generator.text(
        SystemInfo.ticketCredit,
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );

      // Reducido a 2 líneas de espacio final para evitar tanto papel blanco
      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      // ── ENVIAR A IMPRESORA ────────────────────────
      // longData:true es necesario en Windows USB (envía en chunks)
      await _plugin.printData(target, bytes, longData: true);

      return const ResultadoImpresora(
        exito: true,
        mensaje: 'Ticket impreso correctamente.',
      );
    } catch (e) {
      return ResultadoImpresora(exito: false, mensaje: 'Error al imprimir: $e');
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ─────────────────────────────────────────────

  String _formatFecha(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} $h:$m';
  }

  String _fmtMoneda(double v) => 'RD\$ ${v.toStringAsFixed(2)}';

  String _fmtCant(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max - 2)}..' : s;

  /// Remueve acentos y caracteres especiales para evitar errores de codificación
  /// en impresoras térmicas (Ej: "Menú" -> "Menu", "Díaz" -> "Diaz")
  String _limpiarTexto(String text) {
    if (text.isEmpty) return text;
    const conAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÑñ';
    const sinAcento = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuNn';
    String res = text;
    for (int i = 0; i < conAcento.length; i++) {
      res = res.replaceAll(conAcento[i], sinAcento[i]);
    }
    return res;
  }
}
