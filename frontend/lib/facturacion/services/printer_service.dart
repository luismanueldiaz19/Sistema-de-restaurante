import 'dart:async';
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

      // En Windows, USB NO necesita connect() — causa 'Read buffer fail'.
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
  // PING IMPRESORA (Validación rápida)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> pingImpresora() async {
    try {
      if (_printerConectado == null) {
        final conexion = await conectarAutomaticamente();
        if (!conexion.exito) {
          return const ResultadoImpresora(
            exito: false,
            mensaje: 'La impresora no está conectada o está apagada.',
          );
        }
      }

      // Enviar comando inofensivo (ESC @ - Inicializar impresora)
      await _plugin.printData(_printerConectado!, [0x1B, 0x40], longData: true);

      return const ResultadoImpresora(exito: true, mensaje: 'Conectada');
    } catch (e) {
      _printerConectado = null;
      return const ResultadoImpresora(
        exito: false,
        mensaje: 'La impresora no está conectada o está apagada.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // TEST: HOLA MUNDO  (verifica que la impresora funciona)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirPrueba() async {
    try {
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
  // IMPRIMIR RAW BYTES (PARA OTROS SERVICIOS)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> printBytes(
    List<int> bytes, {
    Printer? printer,
  }) async {
    try {
      Printer? target = printer ?? _printerConectado;

      if (target == null) {
        final conexion = await conectarAutomaticamente();
        if (!conexion.exito) {
          return ResultadoImpresora(
            exito: false,
            mensaje: 'Sin impresora conectada. ${conexion.mensaje}',
          );
        }
        target = _printerConectado!;
      }

      await _plugin.printData(target, bytes, longData: true);
      return const ResultadoImpresora(
        exito: true,
        mensaje: 'Impreso correctamente',
      );
    } catch (e) {
      return ResultadoImpresora(
        exito: false,
        mensaje: 'Error al enviar bytes a impresora: $e',
      );
    }
  }

  // ─────────────────────────────────────────────
  // IMPRIMIR FACTURA (CON QR Y CÓDIGO DE SEGURIDAD OFICIAL e-CF DGII)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirFactura({
    required String nombreNegocio,
    required String direccion,
    required String rncOCedula,
    required String numeroFactura,
    String? ncf,
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
    String? metodoPago,
    double? montoRecibido,
    double? devuelta,
    String? qrUrl,
    String? codigoSeguridad,
    String? fechaFirma,
    Printer? printer,
  }) async {
    try {
      Printer? target = printer ?? _printerConectado;

      if (target == null) {
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
        'Tel.: ${Company.current.telefono}',
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

      final String tipoDoc = _resolverTituloComprobante(ncf, rncCliente);
      bytes += generator.text(
        tipoDoc,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );

      final bool esEcf =
          ncf != null && ncf.toUpperCase().startsWith('E') && ncf != 'S/N';

      if (ncf != null && ncf.isNotEmpty && ncf != 'S/N') {
        bytes += generator.text(
          esEcf ? 'e-NCF: $ncf' : 'NCF: $ncf',
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
      }

      bytes += generator.text(
        'Factura No. : $numeroFactura',
        styles: const PosStyles(align: PosAlign.left),
      );
      if (rncCliente != null &&
          rncCliente.isNotEmpty &&
          !RegExp(r'^0+$').hasMatch(rncCliente.replaceAll('-', ''))) {
        bytes += generator.text(
          'RNC Cliente : $rncCliente',
          styles: const PosStyles(align: PosAlign.left),
        );
      }
      bytes += generator.text(
        'Cliente     : $clienteLimpio',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'CONDICION   : ${tipoPago ?? "CONTADO"}',
        styles: const PosStyles(align: PosAlign.left),
      );

      if (nota != null && nota.isNotEmpty) {
        bytes += generator.text(
          'Nota        : ${_limpiarTexto(nota)}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      // ── ENCABEZADO DE ITEMS ───────────────────────
      bytes += generator.hr(ch: '=');

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

      // ── TIMBRE ELECTRÓNICO DGII (QR + CÓDIGO DE SEGURIDAD + FECHA FIRMA) ──
      if (esEcf || (qrUrl != null && qrUrl.isNotEmpty)) {
        bytes += generator.emptyLines(1);

        final rncLimpio = rncOCedula.replaceAll(RegExp(r'[^0-9]'), '');
        final effectiveQr = (qrUrl != null && qrUrl.isNotEmpty)
            ? qrUrl
            : 'https://fc.dgii.gov.do/TesteCF/ConsultaTimbreFC?RncEmisor=$rncLimpio&ENCF=${ncf ?? numeroFactura}&MontoTotal=${total.toStringAsFixed(2)}&CodigoSeguridad=${codigoSeguridad ?? "PENDTE"}';

        bytes += generator.qrcode(effectiveQr);

        if (codigoSeguridad != null && codigoSeguridad.isNotEmpty) {
          bytes += generator.text(
            'Codigo de Seguridad: $codigoSeguridad',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        bytes += generator.text(
          'Fecha de Firma Digital: ${fechaFirma ?? _formatFecha(fecha)}',
          styles: const PosStyles(align: PosAlign.center),
        );
      }

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

      bytes += generator.emptyLines(2);
      bytes += generator.cut();

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
  // IMPRIMIR REPORTE DE CIERRE DE CAJA
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirCierreCaja({
    required Map<String, dynamic> sesion,
    Printer? printer,
  }) async {
    try {
      Printer? target = printer ?? _printerConectado;

      if (target == null) {
        final conexion = await conectarAutomaticamente();
        if (!conexion.exito) {
          return ResultadoImpresora(
            exito: false,
            mensaje: 'Sin impresora conectada. ${conexion.mensaje}',
          );
        }
        target = _printerConectado!;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 2);
      List<int> bytes = [];

      bytes += generator.reset();
      bytes += generator.text(
        'REPORTE DE CIERRE DE CAJA',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'SESION #${sesion['id']}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.emptyLines(1);

      bytes += generator.text(
        'Caja    : ${_limpiarTexto(sesion['caja']?['nombre'] ?? 'N/A')}',
      );
      bytes += generator.text(
        'Turno   : ${_limpiarTexto(sesion['turno']?['nombre'] ?? 'N/A')}',
      );
      bytes += generator.text(
        'Cajero  : ${_limpiarTexto(sesion['usuario']?['name'] ?? 'N/A')}',
      );

      if (sesion['fecha_apertura'] != null) {
        bytes += generator.text('Apertura: ${sesion['fecha_apertura']}');
      }
      if (sesion['fecha_cierre'] != null) {
        bytes += generator.text('Cierre  : ${sesion['fecha_cierre']}');
      } else {
        bytes += generator.text('Cierre  : EN CURSO');
      }
      bytes += generator.hr();

      final mInicial =
          double.tryParse((sesion['monto_inicial'] ?? 0).toString()) ?? 0;
      final mEsperado =
          double.tryParse((sesion['monto_final_esperado'] ?? 0).toString()) ??
          0;
      final mFisico = sesion['monto_final_fisico'] != null
          ? (double.tryParse(sesion['monto_final_fisico'].toString()) ?? 0)
          : null;
      final diff = double.tryParse((sesion['diferencia'] ?? 0).toString()) ?? 0;

      bytes += generator.row([
        PosColumn(text: 'Fondo Inicial:', width: 6),
        PosColumn(
          text: _fmtMoneda(mInicial),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Monto Esperado:', width: 6),
        PosColumn(
          text: _fmtMoneda(mEsperado),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (mFisico != null) {
        bytes += generator.row([
          PosColumn(text: 'Monto Fisico:', width: 6),
          PosColumn(
            text: _fmtMoneda(mFisico),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        bytes += generator.row([
          PosColumn(
            text: 'DIFERENCIA:',
            width: 6,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: _fmtMoneda(diff),
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
      }

      final resumen = sesion['resumen_ventas'];
      if (resumen is List && resumen.isNotEmpty) {
        bytes += generator.hr();
        bytes += generator.text(
          'VENTAS POR METODO:',
          styles: const PosStyles(bold: true),
        );
        for (final m in resumen) {
          final metodo = _limpiarTexto(
            (m['metodo_pago'] ?? '').toString().toUpperCase(),
          );
          final total = double.tryParse((m['total'] ?? 0).toString()) ?? 0;
          bytes += generator.row([
            PosColumn(text: metodo, width: 6),
            PosColumn(
              text: _fmtMoneda(total),
              width: 6,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
        }
      }

      final desglose = sesion['desglose_efectivo'] as Map<String, dynamic>?;
      if (desglose != null && desglose.isNotEmpty) {
        bytes += generator.hr();
        bytes += generator.text(
          'DESGLOSE DE EFECTIVO:',
          styles: const PosStyles(bold: true),
        );
        for (final e in desglose.entries) {
          final cant = int.tryParse(e.value.toString()) ?? 0;
          if (cant > 0) {
            bytes += generator.text('RD\$ ${e.key} x $cant');
          }
        }
      }

      if (sesion['comentario'] != null &&
          sesion['comentario'].toString().trim().isNotEmpty) {
        bytes += generator.hr();
        bytes += generator.text('NOTAS:');
        bytes += generator.text(_limpiarTexto(sesion['comentario'].toString()));
      }

      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      await _plugin.printData(target, bytes, longData: true);
      return const ResultadoImpresora(
        exito: true,
        mensaje: 'Reporte de cierre impreso correctamente.',
      );
    } catch (e) {
      return ResultadoImpresora(
        exito: false,
        mensaje: 'Error al imprimir reporte: $e',
      );
    }
  }

  // ─────────────────────────────────────────────
  // IMPRIMIR NOTA DE CRÉDITO (E34 / B04)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirNotaCredito({
    required String nombreNegocio,
    required String rncOCedula,
    required String direccion,
    required String ncfNota,
    required String ncfFacturaAfectada,
    required String numeroFactura,
    required DateTime fecha,
    required List<ItemFactura> itemsDevueltos,
    required double subtotal,
    required double itbis,
    required double total,
    required String motivo,
    String? cliente,
    String? rncCliente,
    String? qrUrl,
    String? codigoSeguridad,
    String? fechaFirma,
    Printer? printer,
  }) async {
    try {
      Printer? target = printer ?? _printerConectado;

      if (target == null) {
        final conexion = await conectarAutomaticamente();
        if (!conexion.exito) {
          return ResultadoImpresora(
            exito: false,
            mensaje: 'Sin impresora conectada. ${conexion.mensaje}',
          );
        }
        target = _printerConectado!;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 2);
      List<int> bytes = [];

      bytes += generator.reset();

      bytes += generator.text(
        _limpiarTexto(nombreNegocio.toUpperCase()),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        _limpiarTexto(direccion),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'RNC: $rncOCedula',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(1);

      final esElectronica = ncfNota.toUpperCase().startsWith('E');
      bytes += generator.text(
        esElectronica ? 'NOTA DE CREDITO ELECTRONICA' : 'NOTA DE CREDITO',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        esElectronica ? 'e-NCF: $ncfNota' : 'NCF: $ncfNota',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'AFECTA NCF: $ncfFacturaAfectada',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Factura No.: $numeroFactura',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr();

      bytes += generator.text('Fecha   : ${_formatFecha(fecha)}');
      bytes += generator.text(
        'Cliente : ${_limpiarTexto(cliente ?? "Consumidor Final")}',
      );
      if (rncCliente != null && rncCliente.isNotEmpty) {
        bytes += generator.text('RNC/Ced.: $rncCliente');
      }
      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(
          text: 'CANT DESCRIPCION',
          width: 7,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: 'PRECIO',
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
        PosColumn(
          text: 'TOTAL',
          width: 3,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.hr();

      for (final item in itemsDevueltos) {
        final cantStr = _fmtCant(item.cantidad);
        final descStr = _limpiarTexto(_truncate(item.descripcion, 16));
        final precioStr = _fmtMoneda(
          item.precioUnitario,
        ).replaceAll('RD\$ ', '');
        final totalStr = _fmtMoneda(item.total).replaceAll('RD\$ ', '');

        bytes += generator.row([
          PosColumn(text: '$cantStr $descStr', width: 7),
          PosColumn(
            text: precioStr,
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: totalStr,
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(text: 'SUBTOTAL:', width: 6),
        PosColumn(
          text: _fmtMoneda(subtotal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (itbis > 0) {
        bytes += generator.row([
          PosColumn(text: 'ITBIS (18%):', width: 6),
          PosColumn(
            text: _fmtMoneda(itbis),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL DEVUELTO:',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: _fmtMoneda(total),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.hr();
      bytes += generator.text('MOTIVO:');
      bytes += generator.text(_limpiarTexto(motivo));

      if (esElectronica && qrUrl != null && qrUrl.isNotEmpty) {
        bytes += generator.emptyLines(1);
        bytes += generator.qrcode(qrUrl);
        if (codigoSeguridad != null && codigoSeguridad.isNotEmpty) {
          bytes += generator.text(
            'Codigo de Seguridad: $codigoSeguridad',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        if (fechaFirma != null && fechaFirma.isNotEmpty) {
          bytes += generator.text(
            'Fecha de Firma Digital: $fechaFirma',
            styles: const PosStyles(align: PosAlign.center),
          );
        }
      }

      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      await _plugin.printData(target, bytes, longData: true);
      return const ResultadoImpresora(
        exito: true,
        mensaje: 'Nota de Crédito impresa exitosamente.',
      );
    } catch (e) {
      return ResultadoImpresora(
        exito: false,
        mensaje: 'Error al imprimir nota de crédito: $e',
      );
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ─────────────────────────────────────────────

  String _resolverTituloComprobante(String? ncf, String? rncCliente) {
    final upper = (ncf ?? '').toUpperCase();
    if (upper.startsWith('E31')) return 'Factura de Credito Fiscal Electronica';
    if (upper.startsWith('E32')) return 'Factura de Consumo Electronica';
    if (upper.startsWith('E33')) return 'Nota de Debito Electronica';
    if (upper.startsWith('E34')) return 'Nota de Credito Electronica';
    if (upper.startsWith('E44')) return 'Regimenes Especiales Electronico';
    if (upper.startsWith('E45')) return 'Comprobante Gubernamental Electronico';
    if (upper.startsWith('E46')) return 'Comprobante Exportaciones Electronico';

    return (rncCliente != null &&
            rncCliente.replaceAll('-', '').length >= 9 &&
            !RegExp(r'^0+$').hasMatch(rncCliente.replaceAll('-', '')))
        ? 'Factura de Credito Fiscal'
        : 'Factura de Consumo';
  }

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
