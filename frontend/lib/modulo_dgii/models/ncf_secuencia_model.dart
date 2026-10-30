import 'dart:math' as math;

class NcfSecuenciaModel {
  final int id;
  final String tipo;
  final String nombre;
  final String prefijo;
  final int actual;
  final int rangoInicio;
  final int rangoFin;
  final bool activo;

  const NcfSecuenciaModel({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.prefijo,
    required this.actual,
    required this.rangoInicio,
    required this.rangoFin,
    required this.activo,
  });

  String get codigo => '${prefijo.toUpperCase()}$tipo';

  bool get esElectronico => prefijo.toUpperCase() == 'E';

  int get padLength => esElectronico ? 10 : 8;

  int get proximoCorrelativo => math.max(actual + 1, rangoInicio);

  bool get agotada => proximoCorrelativo > rangoFin;

  int get disponibles =>
      agotada ? 0 : math.max(0, (rangoFin - proximoCorrelativo) + 1);

  bool get alertaBaja => activo && !agotada && disponibles <= 50;

  String formatearNcf(int numero) =>
      '$codigo${numero.toString().padLeft(padLength, '0')}';

  String get proximoNcfFormateado =>
      agotada ? 'AGOTADA' : formatearNcf(proximoCorrelativo);

  String get ultimoNcfFormateado =>
      actual <= 0 ? 'Sin emitir' : formatearNcf(actual);

  factory NcfSecuenciaModel.fromJson(Map<String, dynamic> json) {
    return NcfSecuenciaModel(
      id: (json['id'] as num).toInt(),
      tipo: (json['tipo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      prefijo: (json['prefijo'] ?? 'E').toString(),
      actual: int.tryParse((json['actual'] ?? 0).toString()) ?? 0,
      rangoInicio: int.tryParse((json['rango_inicio'] ?? 1).toString()) ?? 1,
      rangoFin:
          int.tryParse((json['rango_fin'] ?? 999999999).toString()) ??
          999999999,
      activo: json['activo'] == true || json['activo'] == 1,
    );
  }
}

