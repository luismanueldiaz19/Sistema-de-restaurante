class EcfSummary {
  final int? id;
  final String encf;
  final String tipoEcf;
  final bool esResumenFc;
  final String codigoSeguridad;
  final String fechaHoraFirma;
  final String qrUrl;
  final bool xsdValido;
  final String ambiente;
  final String? trackId;
  final String estadoDgii;

  const EcfSummary({
    this.id,
    required this.encf,
    required this.tipoEcf,
    this.esResumenFc = false,
    required this.codigoSeguridad,
    required this.fechaHoraFirma,
    required this.qrUrl,
    this.xsdValido = true,
    this.ambiente = 'mock',
    this.trackId,
    this.estadoDgii = 'PENDIENTE',
  });

  factory EcfSummary.fromJson(Map<String, dynamic> json) => EcfSummary(
    id: json['id'],
    encf: (json['encf'] ?? '').toString(),
    tipoEcf: (json['tipo_ecf'] ?? '').toString(),
    esResumenFc: json['es_resumen_fc'] == true || json['es_resumen_fc'] == 1,
    codigoSeguridad: (json['codigo_seguridad'] ?? '').toString(),
    fechaHoraFirma: (json['fecha_hora_firma'] ?? '').toString(),
    qrUrl: (json['qr_url'] ?? '').toString(),
    xsdValido: json['xsd_valido'] == true || json['xsd_valido'] == 1,
    ambiente: (json['ambiente'] ?? 'mock').toString(),
    trackId: json['track_id']?.toString(),
    estadoDgii: (json['estado_dgii'] ?? 'PENDIENTE').toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'encf': encf,
    'tipo_ecf': tipoEcf,
    'es_resumen_fc': esResumenFc,
    'codigo_seguridad': codigoSeguridad,
    'fecha_hora_firma': fechaHoraFirma,
    'qr_url': qrUrl,
    'xsd_valido': xsdValido,
    'ambiente': ambiente,
    'track_id': trackId,
    'estado_dgii': estadoDgii,
  };
}

class EcfConfigModel {
  final String ambiente;
  final String rncEmisor;
  final String razonSocial;
  final String nombreComercial;
  final String direccion;
  final String municipio;
  final String provincia;
  final String telefono;
  final String correo;
  final String sitioWeb;
  final bool envioAutomatico;

  const EcfConfigModel({
    this.ambiente = 'mock',
    this.rncEmisor = '',
    this.razonSocial = '',
    this.nombreComercial = '',
    this.direccion = '',
    this.municipio = '',
    this.provincia = '',
    this.telefono = '',
    this.correo = '',
    this.sitioWeb = '',
    this.envioAutomatico = true,
  });

  factory EcfConfigModel.fromJson(Map<String, dynamic> json) => EcfConfigModel(
    ambiente: (json['ambiente'] ?? 'mock').toString(),
    rncEmisor: (json['rnc_emisor'] ?? '').toString(),
    razonSocial: (json['razon_social'] ?? '').toString(),
    nombreComercial: (json['nombre_comercial'] ?? '').toString(),
    direccion: (json['direccion'] ?? '').toString(),
    municipio: (json['municipio'] ?? '').toString(),
    provincia: (json['provincia'] ?? '').toString(),
    telefono: (json['telefono'] ?? '').toString(),
    correo: (json['correo'] ?? '').toString(),
    sitioWeb: (json['sitio_web'] ?? '').toString(),
    envioAutomatico:
        json['envio_automatico'] == null ||
        json['envio_automatico'] == true ||
        json['envio_automatico'] == 1,
  );
}

class EcfCertificadoMeta {
  final bool existe;
  final bool valido;
  final bool expirado;
  final int diasRestantes;
  final String cn;
  final String organizacion;
  final String emisorCa;
  final String validoDesde;
  final String validoHasta;
  final String archivo;
  final String? error;

  const EcfCertificadoMeta({
    this.existe = false,
    this.valido = false,
    this.expirado = false,
    this.diasRestantes = 0,
    this.cn = '',
    this.organizacion = '',
    this.emisorCa = '',
    this.validoDesde = '',
    this.validoHasta = '',
    this.archivo = '',
    this.error,
  });

  factory EcfCertificadoMeta.fromJson(Map<String, dynamic> json) =>
      EcfCertificadoMeta(
        existe: json['existe'] == true,
        valido: json['valido'] == true,
        expirado: json['expirado'] == true,
        diasRestantes: (json['dias_restantes'] as num?)?.toInt() ?? 0,
        cn: (json['cn'] ?? '').toString(),
        organizacion: (json['organizacion'] ?? '').toString(),
        emisorCa: (json['emisor_ca'] ?? '').toString(),
        validoDesde: (json['valido_desde'] ?? '').toString(),
        validoHasta: (json['valido_hasta'] ?? '').toString(),
        archivo: (json['archivo'] ?? '').toString(),
        error: json['error']?.toString(),
      );
}

class EcfDocumentoItem {
  final int id;
  final int? facturaId;
  final int? notaCreditoId;
  final String encf;
  final String tipoEcf;
  final bool esResumenFc;
  final String rncEmisor;
  final String? rncComprador;
  final String? razonSocialComprador;
  final double totalItbis;
  final double montoTotal;
  final String codigoSeguridad;
  final String fechaEmision;
  final String fechaHoraFirma;
  final String qrUrl;
  final bool xsdValido;
  final String ambiente;
  final String? trackId;
  final String estadoDgii;
  final String? ultimoError;

  const EcfDocumentoItem({
    required this.id,
    this.facturaId,
    this.notaCreditoId,
    required this.encf,
    required this.tipoEcf,
    required this.esResumenFc,
    required this.rncEmisor,
    this.rncComprador,
    this.razonSocialComprador,
    required this.totalItbis,
    required this.montoTotal,
    required this.codigoSeguridad,
    required this.fechaEmision,
    required this.fechaHoraFirma,
    required this.qrUrl,
    required this.xsdValido,
    required this.ambiente,
    this.trackId,
    required this.estadoDgii,
    this.ultimoError,
  });

  factory EcfDocumentoItem.fromJson(Map<String, dynamic> json) =>
      EcfDocumentoItem(
        id: (json['id'] as num).toInt(),
        facturaId: (json['factura_id'] as num?)?.toInt(),
        notaCreditoId: (json['nota_credito_id'] as num?)?.toInt(),
        encf: (json['encf'] ?? '').toString(),
        tipoEcf: (json['tipo_ecf'] ?? '').toString(),
        esResumenFc: json['es_resumen_fc'] == true || json['es_resumen_fc'] == 1,
        rncEmisor: (json['rnc_emisor'] ?? '').toString(),
        rncComprador: json['rnc_comprador']?.toString(),
        razonSocialComprador: json['razon_social_comprador']?.toString(),
        totalItbis:
            double.tryParse((json['total_itbis'] ?? 0).toString()) ?? 0.0,
        montoTotal:
            double.tryParse((json['monto_total'] ?? 0).toString()) ?? 0.0,
        codigoSeguridad: (json['codigo_seguridad'] ?? '').toString(),
        fechaEmision: (json['fecha_emision'] ?? '').toString(),
        fechaHoraFirma: (json['fecha_hora_firma'] ?? '').toString(),
        qrUrl: (json['qr_url'] ?? '').toString(),
        xsdValido: json['xsd_valido'] == true || json['xsd_valido'] == 1,
        ambiente: (json['ambiente'] ?? 'mock').toString(),
        trackId: json['track_id']?.toString(),
        estadoDgii: (json['estado_dgii'] ?? 'PENDIENTE').toString(),
        ultimoError: json['ultimo_error']?.toString(),
      );
}

