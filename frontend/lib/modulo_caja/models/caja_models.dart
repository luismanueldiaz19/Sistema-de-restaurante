class Caja {
  final int id;
  final String nombre;
  final bool activa;

  Caja({required this.id, required this.nombre, this.activa = true});

  factory Caja.fromJson(Map<String, dynamic> json) {
    return Caja(
      id: json['id'],
      nombre: json['nombre'],
      activa: json['activa'] == 1 || json['activa'] == true,
    );
  }
}

class Turno {
  final int id;
  final String nombre;

  Turno({required this.id, required this.nombre});

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}

class CajaSesion {
  final int id;
  final int cajaId;
  final int userId;
  final int turnoId;
  final double montoInicial;
  final double? montoFinalEsperado;
  final double? montoFinalFisico;
  final double diferencia;
  final String estado;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final String? nombreCaja;
  final String? nombreTurno;

  CajaSesion({
    required this.id,
    required this.cajaId,
    required this.userId,
    required this.turnoId,
    required this.montoInicial,
    this.montoFinalEsperado,
    this.montoFinalFisico,
    this.diferencia = 0,
    required this.estado,
    required this.fechaApertura,
    this.fechaCierre,
    this.nombreCaja,
    this.nombreTurno,
  });

  factory CajaSesion.fromJson(Map<String, dynamic> json) {
    return CajaSesion(
      id: json['id'],
      cajaId: json['caja_id'],
      userId: json['user_id'],
      turnoId: json['turno_id'],
      montoInicial: double.parse(json['monto_inicial'].toString()),
      montoFinalEsperado: json['monto_final_esperado'] != null ? double.parse(json['monto_final_esperado'].toString()) : null,
      montoFinalFisico: json['monto_final_fisico'] != null ? double.parse(json['monto_final_fisico'].toString()) : null,
      diferencia: double.parse((json['diferencia'] ?? 0).toString()),
      estado: json['estado'],
      fechaApertura: DateTime.parse(json['fecha_apertura']),
      fechaCierre: json['fecha_cierre'] != null ? DateTime.parse(json['fecha_cierre']) : null,
      nombreCaja: json['caja'] != null ? json['caja']['nombre'] : null,
      nombreTurno: json['turno'] != null ? json['turno']['nombre'] : null,
    );
  }
}
