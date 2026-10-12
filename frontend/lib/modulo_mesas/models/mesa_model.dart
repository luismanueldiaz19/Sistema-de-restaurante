import '../../pedidos/models/pedido.dart';

class MesaModel {
  final int id;
  final String nombre;
  final String area;
  final int capacidad;
  final String estado; // 'Libre', 'Ocupada', 'PorCobrar', 'Inactiva'
  final int? ordenActivaId;
  final Pedido? ordenActiva;
  final String? createdAt;
  final String? updatedAt;

  MesaModel({
    required this.id,
    required this.nombre,
    required this.area,
    required this.capacidad,
    required this.estado,
    this.ordenActivaId,
    this.ordenActiva,
    this.createdAt,
    this.updatedAt,
  });

  factory MesaModel.fromJson(Map<String, dynamic> json) {
    Pedido? orden;
    if (json['orden_activa'] != null && json['orden_activa'] is Map<String, dynamic>) {
      try {
        orden = Pedido.fromJson(json['orden_activa']);
      } catch (_) {
        orden = null;
      }
    }

    return MesaModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      area: json['area'] ?? 'Principal',
      capacidad: json['capacidad'] != null
          ? int.tryParse(json['capacidad'].toString()) ?? 4
          : 4,
      estado: json['estado'] ?? 'Libre',
      ordenActivaId: json['orden_activa_id'] != null
          ? int.tryParse(json['orden_activa_id'].toString())
          : null,
      ordenActiva: orden,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'area': area,
      'capacidad': capacidad,
      'estado': estado,
      'orden_activa_id': ordenActivaId,
    };
  }

  MesaModel copyWith({
    int? id,
    String? nombre,
    String? area,
    int? capacidad,
    String? estado,
    int? ordenActivaId,
    Pedido? ordenActiva,
    bool clearOrdenActiva = false,
  }) {
    return MesaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      area: area ?? this.area,
      capacidad: capacidad ?? this.capacidad,
      estado: estado ?? this.estado,
      ordenActivaId: clearOrdenActiva ? null : (ordenActivaId ?? this.ordenActivaId),
      ordenActiva: clearOrdenActiva ? null : (ordenActiva ?? this.ordenActiva),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isLibre => estado == 'Libre';
  bool get isOcupada => estado == 'Ocupada';
  bool get isPorCobrar => estado == 'PorCobrar';
  bool get isInactiva => estado == 'Inactiva';
  double get totalConsumo => ordenActiva?.total ?? 0.0;
}
