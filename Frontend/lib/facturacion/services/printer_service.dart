import 'dart:async';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import '../../model/company.dart';
import '../../modulo_cliente/models/cliente.dart';

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

/// Servicio singleton para impresión térmica USB (80mm) adaptado a Company.current y DGII e-CF
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
  // ABRIR CAJÓN DE DINERO (GAVETA RJ11 CONECTADA AL PRINTER)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> abrirCajon({Printer? printer}) async {
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

      // Comando estándar ESC/POS (ESC p m t1 t2) para abrir gaveta por Pin 2 y Pin 5
      final List<int> bytes = [
        0x1B, 0x40, // ESC @ (Inicializar)
        0x1B, 0x70, 0x00, 0x19, 0xFA, // Pin 2 (m=0, 50ms ON, 500ms OFF)
        0x1B, 0x70, 0x01, 0x19, 0xFA, // Pin 5 (m=1, 50ms ON, 500ms OFF)
      ];

      await _plugin.printData(target, bytes, longData: true);

      return const ResultadoImpresora(
        exito: true,
        mensaje: 'Cajón de dinero abierto.',
      );
    } catch (e) {
      _printerConectado = null;
      return ResultadoImpresora(
        exito: false,
        mensaje: 'Error al abrir el cajón: $e',
      );
    }
  }

  // ─────────────────────────────────────────────
  // TEST DE IMPRESORA (DINÁMICO CON COMPANY.CURRENT)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirPrueba({Company? company}) async {
    try {
      if (_printerConectado == null) {
        final conexion = await conectarAutomaticamente();
        if (!conexion.exito) return conexion;
      }

      final emp = company ?? Company.current;
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.reset();
      bytes += _agregarEncabezadoEmpresa(generator, company: emp);
      bytes += generator.hr(ch: '-');
      bytes += generator.text(
        'PRUEBA DE IMPRESORA OK',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'Fecha: ${_formatFecha(DateTime.now())}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Ambiente DGII: ${emp.ambienteDgii}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr(ch: '-');
      bytes += _agregarPieEmpresa(
        generator,
        company: emp,
        incluirPoliticas: false,
      );
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
  // IMPRIMIR FACTURA (DINÁMICA CON COMPANY Y e-CF DGII)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirFactura({
    Company? company,
    String? nombreNegocio,
    String? direccion,
    String? rncOCedula,
    required String numeroFactura,
    String? ncf,
    required DateTime fecha,
    required List<ItemFactura> items,
    required double subtotal,
    required double impuesto,
    required double descuento,
    required double total,
    Cliente? clienteModel,
    String? cliente,
    String? rncCliente,
    String? telefonoCliente,
    String? direccionCliente,
    String? emailCliente,
    String? cajero,
    String? nota,
    String? tipoPago,
    int? diasCredito,
    String? metodoPago,
    double? montoRecibido,
    double? devuelta,
    String? qrUrl,
    String? codigoSeguridad,
    String? fechaFirma,
    String? copiaTexto,
    bool abrirCajon = false,
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

      // Siempre toma los datos de la clase Company.current (o la instancia recibida)
      final emp = company ?? Company.current;

      // Resolver datos completos del cliente (desde clienteModel o parámetros individuales)
      final rawNombreCli = (clienteModel?.nombre ?? cliente ?? '').trim();
      final clienteLimpio = _limpiarTexto(
        rawNombreCli.isNotEmpty ? rawNombreCli : 'Consumidor Final',
      );
      final rawRncCli = (clienteModel?.rncCedula ?? rncCliente ?? '').trim();
      final rawTelCli = (clienteModel?.telefono ?? telefonoCliente ?? '')
          .trim();
      final rawDirCli = (clienteModel?.direccion ?? direccionCliente ?? '')
          .trim();
      final rawEmailCli = (clienteModel?.email ?? emailCliente ?? '').trim();

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 2);
      List<int> bytes = [];

      bytes += generator.reset();

      if (abrirCajon) {
        // Abrir cajón de dinero conectado por RJ11 (Pin 2 y Pin 5)
        bytes += [0x1B, 0x70, 0x00, 0x19, 0xFA, 0x1B, 0x70, 0x01, 0x19, 0xFA];
      }

      // ── 1. ENCABEZADO DINÁMICO DESDE COMPANY.CURRENT ──────
      bytes += _agregarEncabezadoEmpresa(
        generator,
        company: emp,
        nombreOverride: nombreNegocio,
        direccionOverride: direccion,
        rncOverride: rncOCedula,
      );
      bytes += generator.hr(ch: '-');

      if (copiaTexto != null && copiaTexto.trim().isNotEmpty) {
        bytes += generator.text(
          '*** ${copiaTexto.trim().toUpperCase()} ***',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        bytes += generator.hr(ch: '-');
      }

      // ── 2. TIPO DE COMPROBANTE Y NCF / e-NCF ──────────────
      final String tipoDoc = _resolverTituloComprobante(ncf, rawRncCli);
      bytes += generator.text(
        tipoDoc.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      final bool esEcf =
          ncf != null && ncf.toUpperCase().startsWith('E') && ncf != 'S/N';

      if (ncf != null && ncf.isNotEmpty && ncf != 'S/N') {
        bytes += generator.text(
          esEcf ? 'e-NCF: $ncf' : 'NCF: $ncf',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
      }
      bytes += generator.hr(ch: '-');

      // ── 3. DATOS DE LA FACTURA, CLIENTE Y MÉTODO DE PAGO ──
      bytes += generator.text(
        'Fecha         : ${_formatFecha(fecha)}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'Factura No.   : #$numeroFactura',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      if (cajero != null && cajero.trim().isNotEmpty) {
        bytes += generator.text(
          'Atendido por  : ${_limpiarTexto(cajero)}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      // Información del Cliente (Nombre + RNC + Teléfono + Dirección si existen)
      bytes += generator.text(
        'Cliente       : $clienteLimpio',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );

      final rncCliSoloDigitos = rawRncCli.replaceAll(RegExp(r'[^0-9]'), '');
      final tieneRncCli =
          rncCliSoloDigitos.isNotEmpty &&
          !RegExp(r'^0+$').hasMatch(rncCliSoloDigitos);

      if (tieneRncCli) {
        bytes += generator.text(
          'RNC / Cedula  : $rawRncCli',
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
      }

      final telCliSoloDigitos = rawTelCli.replaceAll(RegExp(r'[^0-9]'), '');
      if (telCliSoloDigitos.isNotEmpty &&
          !RegExp(r'^0+$').hasMatch(telCliSoloDigitos)) {
        bytes += generator.text(
          'Tel. Cliente  : $rawTelCli',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      if (rawDirCli.isNotEmpty &&
          rawDirCli.toLowerCase() != 'n/a' &&
          rawDirCli.toLowerCase() != 'sin direccion') {
        bytes += generator.text(
          'Dir. Cliente  : ${_limpiarTexto(rawDirCli)}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      if (rawEmailCli.isNotEmpty && rawEmailCli.contains('@')) {
        bytes += generator.text(
          'Correo Cli.   : $rawEmailCli',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      // Condición y Método de Pago Efectuado
      final bool esCredito = (tipoPago ?? '').toUpperCase() == 'CREDITO';
      final String metodoEfectuado = _resolverNombreMetodoPago(
        metodoPago: metodoPago,
        esCredito: esCredito,
        diasCredito: diasCredito,
      );

      bytes += generator.text(
        'Condicion     : ${esCredito ? "CREDITO${diasCredito != null && diasCredito > 0 ? ' ($diasCredito DIAS)' : ''}" : "CONTADO"}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'Metodo Pago   : $metodoEfectuado',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );

      if (nota != null && nota.trim().isNotEmpty) {
        bytes += generator.text(
          'Nota          : ${_limpiarTexto(nota)}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      // ── 4. TABLA DE ARTÍCULOS ─────────────────────────────
      bytes += generator.hr(ch: '=');

      String buildRow(String c1, String c2, String c3, String c4) {
        return c1.padRight(21) +
            c2.padLeft(4) +
            c3.padLeft(10) +
            c4.padLeft(13);
      }

      bytes += generator.text(
        buildRow('Descripcion', 'Cant', 'P.Unit', 'Importe'),
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.hr(ch: '-');

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

      // ── 5. SECCIÓN FINAL LIMPIA: TOTALES Y PAGO ───────────
      bytes += generator.hr(ch: '-');

      String buildSummaryLine(String label, String value) {
        return '${label.padLeft(30)} : ${value.padLeft(15)}';
      }

      bytes += generator.text(
        buildSummaryLine('Subtotal', _fmtMoneda(subtotal)),
        styles: const PosStyles(align: PosAlign.left),
      );
      if (descuento > 0) {
        bytes += generator.text(
          buildSummaryLine('Descuento', '-${_fmtMoneda(descuento)}'),
          styles: const PosStyles(align: PosAlign.left),
        );
      }
      bytes += generator.text(
        buildSummaryLine('ITBIS (18%)', _fmtMoneda(impuesto)),
        styles: const PosStyles(align: PosAlign.left),
      );

      bytes += generator.hr(ch: '=');

      String buildTotalBig(String label, String value) {
        return label.padRight(10) + value.padLeft(14);
      }

      bytes += generator.text(
        buildTotalBig('TOTAL', _fmtMoneda(total)),
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.hr(ch: '-');

      // Desglose limpio del pago efectuado
      if (!esCredito) {
        final double recibidoEfectivo =
            (montoRecibido != null && montoRecibido > 0)
            ? montoRecibido
            : total;
        bytes += generator.text(
          buildSummaryLine(
            'Pagado ($metodoEfectuado)',
            _fmtMoneda(recibidoEfectivo),
          ),
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
        if (devuelta != null && devuelta > 0) {
          bytes += generator.text(
            buildSummaryLine('Cambio / Devuelta', _fmtMoneda(devuelta)),
            styles: const PosStyles(align: PosAlign.left, bold: true),
          );
        }
      } else {
        bytes += generator.text(
          buildSummaryLine('Pendiente a Credito', _fmtMoneda(total)),
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
      }

      // ── 6. TIMBRE ELECTRÓNICO DGII (QR + CÓDIGO + FECHA FIRMA) ──
      if (esEcf || (qrUrl != null && qrUrl.isNotEmpty)) {
        bytes += generator.hr(ch: '-');
        bytes += generator.emptyLines(1);

        final effectiveQr = (qrUrl != null && qrUrl.isNotEmpty)
            ? qrUrl
            : emp.construirUrlQrDgii(
                encf: ncf ?? numeroFactura,
                montoTotal: total,
                codigoSeguridad: codigoSeguridad,
              );

        bytes += generator.qrcode(effectiveQr);

        if (codigoSeguridad != null && codigoSeguridad.isNotEmpty) {
          bytes += generator.text(
            'Codigo de Seguridad: $codigoSeguridad',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        bytes += generator.text(
          'Firma Digital: ${_formatFechaString(fechaFirma, fecha)}',
          styles: const PosStyles(
            align: PosAlign.center,
            fontType: PosFontType.fontB,
          ),
        );
      }

      // Firma del cliente si es copia de establecimiento / comercio
      if (copiaTexto != null &&
          (copiaTexto.toUpperCase().contains('ESTABLECIMIENTO') ||
              copiaTexto.toUpperCase().contains('COMERCIO') ||
              copiaTexto.toUpperCase().contains('NEGOCIO'))) {
        bytes += generator.emptyLines(2);
        bytes += generator.text(
          '________________________________',
          styles: const PosStyles(align: PosAlign.center),
        );
        bytes += generator.text(
          'FIRMA DEL CLIENTE',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
        bytes += generator.emptyLines(1);
      }

      // ── 7. PIE DE PÁGINA LIMPIO Y COMPACTO ────────────────
      bytes += generator.hr(ch: '-');
      bytes += _agregarPieEmpresa(
        generator,
        company: emp,
        incluirPoliticas: true,
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
    Company? company,
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

      final emp = company ?? Company.current;
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 2);
      List<int> bytes = [];

      bytes += generator.reset();
      bytes += _agregarEncabezadoEmpresa(generator, company: emp);
      bytes += generator.hr(ch: '-');
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
        bytes += generator.text(
          'Apertura: ${_formatFechaString(sesion['fecha_apertura']?.toString(), DateTime.now())}',
        );
      }
      if (sesion['fecha_cierre'] != null) {
        bytes += generator.text(
          'Cierre  : ${_formatFechaString(sesion['fecha_cierre']?.toString(), DateTime.now())}',
        );
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

      bytes += generator.hr(ch: '-');
      bytes += _agregarPieEmpresa(
        generator,
        company: emp,
        incluirPoliticas: false,
      );
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
  // IMPRIMIR NOTA DE CRÉDITO (E34 / B04 - DINÁMICO CON COMPANY)
  // ─────────────────────────────────────────────
  Future<ResultadoImpresora> imprimirNotaCredito({
    Company? company,
    String? nombreNegocio,
    String? rncOCedula,
    String? direccion,
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
    String? copiaTexto,
    bool abrirCajon = false,
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

      final emp = company ?? Company.current;
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 2);
      List<int> bytes = [];

      bytes += generator.reset();
      if (abrirCajon) {
        bytes += [0x1B, 0x70, 0x00, 0x19, 0xFA, 0x1B, 0x70, 0x01, 0x19, 0xFA];
      }

      // ── ENCABEZADO DINÁMICO DE LA EMPRESA ──
      bytes += _agregarEncabezadoEmpresa(
        generator,
        company: emp,
        nombreOverride: nombreNegocio,
        direccionOverride: direccion,
        rncOverride: rncOCedula,
      );
      bytes += generator.hr(ch: '-');

      if (copiaTexto != null && copiaTexto.trim().isNotEmpty) {
        bytes += generator.text(
          '*** ${copiaTexto.trim().toUpperCase()} ***',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        bytes += generator.hr(ch: '-');
      }

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
        'Factura No.: #$numeroFactura',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr(ch: '-');

      bytes += generator.text('Fecha   : ${_formatFecha(fecha)}');
      bytes += generator.text(
        'Cliente : ${_limpiarTexto(cliente ?? "Consumidor Final")}',
        styles: const PosStyles(bold: true),
      );
      if (rncCliente != null &&
          rncCliente.trim().isNotEmpty &&
          !RegExp(r'^0+$').hasMatch(rncCliente.replaceAll('-', ''))) {
        bytes += generator.text('RNC/Ced.: $rncCliente');
      }
      bytes += generator.hr(ch: '-');

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
      bytes += generator.hr(ch: '-');

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

      bytes += generator.hr(ch: '-');

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

      bytes += generator.hr(ch: '-');
      bytes += generator.text('Motivo: ${_limpiarTexto(motivo)}');

      if (esElectronica || (qrUrl != null && qrUrl.isNotEmpty)) {
        bytes += generator.hr(ch: '-');
        bytes += generator.emptyLines(1);
        final effectiveQr = (qrUrl != null && qrUrl.isNotEmpty)
            ? qrUrl
            : emp.construirUrlQrDgii(
                encf: ncfNota,
                montoTotal: total,
                codigoSeguridad: codigoSeguridad,
              );
        bytes += generator.qrcode(effectiveQr);
        if (codigoSeguridad != null && codigoSeguridad.isNotEmpty) {
          bytes += generator.text(
            'Codigo de Seguridad: $codigoSeguridad',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        bytes += generator.text(
          'Firma Digital: ${_formatFechaString(fechaFirma, fecha)}',
          styles: const PosStyles(
            align: PosAlign.center,
            fontType: PosFontType.fontB,
          ),
        );
      }

      bytes += generator.hr(ch: '-');
      bytes += _agregarPieEmpresa(
        generator,
        company: emp,
        incluirPoliticas: false,
      );
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
  // HELPERS DE ENCABEZADO Y PIE DINÁMICOS (COMPANY)
  // ─────────────────────────────────────────────

  List<int> _agregarEncabezadoEmpresa(
    Generator generator, {
    Company? company,
    String? nombreOverride,
    String? direccionOverride,
    String? rncOverride,
  }) {
    // Siempre toma la información de la clase Company.current
    final emp = company ?? Company.current;
    final nombre = _limpiarTexto((nombreOverride ?? emp.nombre).toUpperCase());
    final direccion = _limpiarTexto(direccionOverride ?? emp.direccionCompleta);
    final rnc = (rncOverride ?? emp.rnc).trim();

    List<int> bytes = [];

    // Nombre comercial en grande / negrita
    bytes += generator.text(
      nombre,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    // Razón social si difiere del nombre comercial
    if (emp.razonSocial != null &&
        emp.razonSocial!.trim().isNotEmpty &&
        emp.razonSocial!.trim().toLowerCase() != emp.nombre.toLowerCase()) {
      bytes += generator.text(
        _limpiarTexto(emp.razonSocial!.toUpperCase()),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    // Slogan si está configurado
    if (emp.slogan.trim().isNotEmpty) {
      bytes += generator.text(
        _limpiarTexto(emp.slogan),
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );
    }

    // Dirección
    if (direccion.isNotEmpty) {
      bytes += generator.text(
        direccion,
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // Sucursal si aplica
    if (emp.sucursal != null && emp.sucursal!.trim().isNotEmpty) {
      bytes += generator.text(
        'Sucursal: ${_limpiarTexto(emp.sucursal!)}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // Teléfonos
    if (emp.telefonosFormateados.trim().isNotEmpty) {
      bytes += generator.text(
        'Tel.: ${emp.telefonosFormateados}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // Correo si está configurado
    if (emp.correo != null && emp.correo!.trim().isNotEmpty) {
      bytes += generator.text(
        emp.correo!.trim(),
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );
    }

    // RNC del Emisor (obligatorio DGII)
    if (rnc.isNotEmpty) {
      bytes += generator.text(
        'RNC: $rnc',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    return bytes;
  }

  List<int> _agregarPieEmpresa(
    Generator generator, {
    Company? company,
    bool incluirPoliticas = true,
  }) {
    final emp = company ?? Company.current;
    List<int> bytes = [];

    if (emp.mensajeAgradecimiento != null &&
        emp.mensajeAgradecimiento!.trim().isNotEmpty) {
      bytes += generator.text(
        _limpiarTexto(emp.mensajeAgradecimiento!),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    if (incluirPoliticas && emp.mensajePieTicket.trim().isNotEmpty) {
      bytes += generator.text(
        _limpiarTexto(emp.mensajePieTicket),
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );
    }

    if (emp.sitioWeb != null && emp.sitioWeb!.trim().isNotEmpty) {
      bytes += generator.text(
        emp.sitioWeb!.trim(),
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );
    }

    bytes += generator.text(
      SystemInfo.ticketCredit,
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    );

    return bytes;
  }

  // ─────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ─────────────────────────────────────────────

  String _resolverNombreMetodoPago({
    String? metodoPago,
    required bool esCredito,
    int? diasCredito,
  }) {
    if (esCredito) {
      return diasCredito != null && diasCredito > 0
          ? 'CREDITO ($diasCredito DIAS)'
          : 'CREDITO';
    }
    final raw = (metodoPago ?? '').trim();
    if (raw.isEmpty) return 'EFECTIVO';
    final limpio = _limpiarTexto(raw.toUpperCase());
    if (limpio == 'CONTADO') return 'EFECTIVO';
    return limpio;
  }

  String _resolverTituloComprobante(String? ncf, String? rncCliente) {
    final upper = (ncf ?? '').toUpperCase();
    // Serie E (Facturación Electrónica e-CF DGII)
    if (upper.startsWith('E31')) return 'Factura de Credito Fiscal Electronica';
    if (upper.startsWith('E32')) return 'Factura de Consumo Electronica';
    if (upper.startsWith('E33')) return 'Nota de Debito Electronica';
    if (upper.startsWith('E34')) return 'Nota de Credito Electronica';
    if (upper.startsWith('E44')) return 'Regimenes Especiales Electronico';
    if (upper.startsWith('E45')) return 'Comprobante Gubernamental Electronico';
    if (upper.startsWith('E46')) return 'Comprobante Exportaciones Electronico';

    // Serie B (Comprobantes Fiscales Tradicionales DGII)
    if (upper.startsWith('B01')) return 'Factura de Credito Fiscal';
    if (upper.startsWith('B02')) return 'Factura de Consumo';
    if (upper.startsWith('B03')) return 'Nota de Debito';
    if (upper.startsWith('B04')) return 'Nota de Credito';
    if (upper.startsWith('B14')) return 'Comprobante Regimen Especial';
    if (upper.startsWith('B15')) return 'Comprobante Gubernamental';
    if (upper.startsWith('B16')) return 'Comprobante de Exportaciones';

    return (rncCliente != null &&
            rncCliente.replaceAll('-', '').length >= 9 &&
            !RegExp(r'^0+$').hasMatch(rncCliente.replaceAll('-', '')))
        ? 'Factura de Credito Fiscal'
        : 'Factura de Consumo';
  }

  /// Formato de fecha en español con hora en formato 12h AM/PM:
  /// Ej: "30 de Oct 2026, 06:25 PM"
  String _formatFecha(DateTime fecha) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;

    final int h12 = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
    final String hora = h12.toString().padLeft(2, '0');
    final String min = fecha.minute.toString().padLeft(2, '0');
    final String amPm = fecha.hour >= 12 ? 'PM' : 'AM';

    return '$dia de $mes $anio, $hora:$min $amPm';
  }

  /// Convierte un string de fecha (ISO o "DD-MM-YYYY HH:mm:ss") a formato español AM/PM
  String _formatFechaString(String? raw, DateTime fallback) {
    if (raw == null || raw.trim().isEmpty) return _formatFecha(fallback);
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) return _formatFecha(parsed.toLocal());

    // Intentar formato DD-MM-YYYY HH:mm:ss o DD/MM/YYYY HH:mm:ss
    final match = RegExp(
      r'^(\d{2})[-/](\d{2})[-/](\d{4})\s+(\d{2}):(\d{2})',
    ).firstMatch(raw.trim());
    if (match != null) {
      final d = int.tryParse(match.group(1)!) ?? fallback.day;
      final mo = int.tryParse(match.group(2)!) ?? fallback.month;
      final y = int.tryParse(match.group(3)!) ?? fallback.year;
      final h = int.tryParse(match.group(4)!) ?? fallback.hour;
      final mi = int.tryParse(match.group(5)!) ?? fallback.minute;
      return _formatFecha(DateTime(y, mo, d, h, mi));
    }

    return raw;
  }

  String _fmtMoneda(double v) => 'RD\$ ${v.toStringAsFixed(2)}';

  String _fmtCant(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max - 2)}..' : s;

  String _limpiarTexto(String text) {
    if (text.isEmpty) return text;
    const conAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÑñ¡!';
    const sinAcento = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuNn !';
    String res = text;
    for (int i = 0; i < conAcento.length; i++) {
      res = res.replaceAll(conAcento[i], sinAcento[i]);
    }
    return res;
  }
}
