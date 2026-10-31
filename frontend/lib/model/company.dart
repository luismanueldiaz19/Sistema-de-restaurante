/// Datos de la empresa / negocio.
/// Edita [current] con la información real del negocio.
class Company {
  // ── DATOS DEL NEGOCIO ─────────────────────────────
  final String nombre;
  final String slogan;
  final String rnc;
  final String direccion;
  final String ciudad;
  final String pais;
  final String telefono;
  final String? telefono2;
  final String? correo;
  final String? sitioWeb;
  final String? logoPath; // ruta del asset (ej: 'assets/logo.png')

  const Company({
    required this.nombre,
    required this.rnc,
    required this.direccion,
    required this.ciudad,
    required this.pais,
    required this.telefono,
    this.slogan = '',
    this.telefono2,
    this.correo,
    this.sitioWeb,
    this.logoPath,
  });

  /// Dirección completa: "Calle X, Santiago, RD"
  String get direccionCompleta => '$direccion, $ciudad, $pais';

  /// Línea de encabezado de ticket: nombre + RNC
  String get encabezadoTicket => '$nombre  |  RNC: $rnc';

  // ──────────────────────────────────────────────────
  // INSTANCIA ACTIVA DEL NEGOCIO  ← edita aquí
  // ──────────────────────────────────────────────────
  static const Company current = Company(
    nombre: 'Menuxa',
    slogan: 'Todo tu restaurante en un solo lugar',
    rnc: '402-2412952-4',
    direccion: 'Direccion del Restaurante',
    ciudad: 'Santiago de los Caballeros',
    pais: 'Rep. Dom',
    telefono: '809-769-9580',
    telefono2: null,
    correo: 'info@menuxa.com',
    sitioWeb: 'www.menuxa.com',
    logoPath: 'assets/icon/app_icon_1.png',
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
  static const String ticketCredit = 'Powered by $systemName · $developerName';

  /// Línea corta para ticket (80mm)
  static const String ticketCreditShort = 'Powered by Lwader-Soft';
}
