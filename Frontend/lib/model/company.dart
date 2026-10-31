/// Datos de la empresa / negocio (Emisor para Facturación y e-CF DGII).
/// Edita [Company.current] con la información real de la empresa donde se despliegue el sistema.
class Company {
  // ── DATOS DEL NEGOCIO (EMISOR) ────────────────────
  final String nombre;
  final String? razonSocial;
  final String slogan;
  final String rnc;
  final String direccion;
  final String ciudad;
  final String pais;
  final String? sucursal;
  final String telefono;
  final String? telefono2;
  final String? correo;
  final String? sitioWeb;
  final String? logoPath; // ruta del asset (ej: 'assets/logo.png')

  // ── CONFIGURACIÓN DE TICKET Y DGII e-CF ───────────
  /// Ambiente DGII para timbre electrónico: 'TesteCF', 'CerteCF' o 'eCF'
  final String ambienteDgii;

  /// Políticas / nota legal al pie de la factura impresa
  final String mensajePieTicket;

  /// Mensaje corto de agradecimiento al final del ticket
  final String? mensajeAgradecimiento;

  const Company({
    required this.nombre,
    required this.rnc,
    required this.direccion,
    required this.ciudad,
    required this.pais,
    required this.telefono,
    this.razonSocial,
    this.slogan = '',
    this.sucursal,
    this.telefono2,
    this.correo,
    this.sitioWeb,
    this.logoPath,
    this.ambienteDgii = 'TesteCF',
    this.mensajePieTicket =
        'Revise su orden antes de retirarse. Indispensable presentar esta factura para reclamos.',
    this.mensajeAgradecimiento = '¡Gracias por preferirnos!',
  });

  /// Dirección completa formateada: "Calle X, Santiago, Rep. Dom"
  String get direccionCompleta => [
    direccion,
    ciudad,
    pais,
  ].where((parte) => parte.trim().isNotEmpty).join(', ');

  /// Teléfonos formateados ("809-000-0000" o "809-000-0000 / 829-000-0000")
  String get telefonosFormateados =>
      (telefono2 != null && telefono2!.trim().isNotEmpty)
      ? '$telefono / $telefono2'
      : telefono;

  /// RNC / Cédula solo con dígitos (requerido para parámetros de URL DGII)
  String get rncLimpio => rnc.replaceAll(RegExp(r'[^0-9]'), '');

  /// Línea de encabezado de ticket: nombre + RNC
  String get encabezadoTicket => '$nombre  |  RNC: $rnc';

  /// Construye la URL oficial del timbre electrónico e-CF de la DGII
  /// cuando el backend aún no provee una URL firmada.
  String construirUrlQrDgii({
    required String encf,
    required double montoTotal,
    String? codigoSeguridad,
  }) {
    final cod = (codigoSeguridad != null && codigoSeguridad.trim().isNotEmpty)
        ? codigoSeguridad.trim()
        : 'PENDTE';
    return 'https://fc.dgii.gov.do/$ambienteDgii/ConsultaTimbreFC'
        '?RncEmisor=$rncLimpio'
        '&ENCF=$encf'
        '&MontoTotal=${montoTotal.toStringAsFixed(2)}'
        '&CodigoSeguridad=$cod';
  }

  // ──────────────────────────────────────────────────
  // INSTANCIA ACTIVA DEL NEGOCIO  ← edita aquí por empresa
  // ──────────────────────────────────────────────────
  static const Company current = Company(
    nombre: 'Menuxa',
    razonSocial: null,
    slogan: 'Todo tu restaurante en un solo lugar',
    rnc: '402-2412952-4',
    direccion: 'Direccion del Restaurante',
    ciudad: 'Santiago de los Caballeros',
    pais: 'Rep. Dom',
    sucursal: null,
    telefono: '809-769-9580',
    telefono2: null,
    correo: '--',
    sitioWeb: null,
    logoPath: 'assets/icon/app_icon_1.png',
    ambienteDgii: 'TesteCF',
    mensajePieTicket:
        'Revise su orden antes de retirarse. Indispensable presentar esta factura para reclamos.',
    mensajeAgradecimiento: '¡Gracias por preferirnos!',
  );
}

// ──────────────────────────────────────────────────
// INFORMACIÓN DEL SISTEMA Y DESARROLLADOR
// ──────────────────────────────────────────────────
class SystemInfo {
  /// Nombre comercial del sistema
  static const String systemName = 'Menuxa';

  /// Versión del sistema
  static const String version = '2.0.0';

  /// Empresa desarrolladora
  static const String developerName = 'Lwader-Soft';

  /// Sitio web del desarrollador
  static const String developerWeb = 'www.lwader-soft.com';

  /// Línea de crédito que aparece al pie del ticket
  static const String ticketCredit = 'Powered by $systemName - $developerName';

  /// Línea corta para ticket (80mm)
  static const String ticketCreditShort = 'Powered by Lwader-Soft';
}
