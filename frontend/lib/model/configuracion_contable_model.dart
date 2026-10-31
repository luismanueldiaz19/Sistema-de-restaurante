import 'catalogo_cuenta_model.dart';

class ConfiguracionContableModel {
  final int id;
  final String clave;
  final String nombre;
  final String grupo;
  final int? cuentaId;
  final CatalogoCuentaModel? cuenta;

  ConfiguracionContableModel({
    required this.id,
    required this.clave,
    required this.nombre,
    required this.grupo,
    this.cuentaId,
    this.cuenta,
  });

  factory ConfiguracionContableModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionContableModel(
      id: json['id'] as int,
      clave: json['clave'] as String,
      nombre: json['nombre'] as String,
      grupo: json['grupo'] as String,
      cuentaId: json['cuenta_id'] as int?,
      cuenta: json['cuenta'] != null
          ? CatalogoCuentaModel.fromJson(json['cuenta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clave': clave,
      'nombre': nombre,
      'grupo': grupo,
      'cuenta_id': cuentaId,
      'cuenta': cuenta?.toJson(),
    };
  }
}
