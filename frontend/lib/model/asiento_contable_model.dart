import 'package:sistema_restaurante/model/catalogo_cuenta_model.dart';
import 'package:sistema_restaurante/model/user.dart';

class AsientoDetalleModel {
  final int id;
  final int asientoId;
  final int cuentaId;
  final double debito;
  final double credito;
  final CatalogoCuentaModel? cuenta;

  AsientoDetalleModel({
    required this.id,
    required this.asientoId,
    required this.cuentaId,
    required this.debito,
    required this.credito,
    this.cuenta,
  });

  factory AsientoDetalleModel.fromJson(Map<String, dynamic> json) {
    return AsientoDetalleModel(
      id: json['id'] as int,
      asientoId: json['asiento_id'] as int,
      cuentaId: json['cuenta_id'] as int,
      debito: double.parse((json['debito'] ?? 0).toString()),
      credito: double.parse((json['credito'] ?? 0).toString()),
      cuenta: json['cuenta'] != null
          ? CatalogoCuentaModel.fromJson(json['cuenta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AsientoContableModel {
  final int id;
  final String fecha;
  final String? glosa;
  final String? referencia;
  final int? usuarioId;
  final String estado;
  final List<AsientoDetalleModel> detalles;
  final User? usuario;

  AsientoContableModel({
    required this.id,
    required this.fecha,
    this.glosa,
    this.referencia,
    this.usuarioId,
    required this.estado,
    required this.detalles,
    this.usuario,
  });

  factory AsientoContableModel.fromJson(Map<String, dynamic> json) {
    final list = json['detalles'] as List<dynamic>? ?? const [];
    final detailsList = list
        .map((i) => AsientoDetalleModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return AsientoContableModel(
      id: json['id'] as int,
      fecha: json['fecha'] as String,
      glosa: json['glosa'] as String?,
      referencia: json['referencia'] as String?,
      usuarioId: json['usuario_id'] as int?,
      estado: json['estado'] as String? ?? 'Posteado',
      detalles: detailsList,
      usuario: json['usuario'] != null
          ? User.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
    );
  }
}
