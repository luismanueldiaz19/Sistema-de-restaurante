class PedidoDetalle {
  final int? id;
  final int? pedidoId;
  final int? productoId;
  final String nombreProducto;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;

  PedidoDetalle({
    this.id,
    this.pedidoId,
    this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory PedidoDetalle.fromJson(Map<String, dynamic> json) {
    return PedidoDetalle(
      id: json['id'],
      pedidoId: json['pedido_id'],
      productoId: json['producto_id'],
      nombreProducto: json['nombre_producto'],
      cantidad: double.parse(json['cantidad'].toString()),
      precioUnitario: double.parse(json['precio_unitario'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class Pedido {
  final int? id;
  final int secuenciaDiaria;
  final String fecha;
  final String clienteNombre;
  final String clienteTelefono;
  final String? direccion;
  final String tipoEntrega;
  final String estado;
  final double total;
  final String? nota;
  final int? facturaId;
  final String? codigoBarras;
  final List<PedidoDetalle> detalles;

  Pedido({
    this.id,
    required this.secuenciaDiaria,
    required this.fecha,
    required this.clienteNombre,
    required this.clienteTelefono,
    this.direccion,
    required this.tipoEntrega,
    required this.estado,
    required this.total,
    this.nota,
    this.facturaId,
    this.codigoBarras,
    required this.detalles,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    var list = json['detalles'] as List? ?? [];
    List<PedidoDetalle> detallesList =
        list.map((i) => PedidoDetalle.fromJson(i)).toList();

    return Pedido(
      id: json['id'],
      secuenciaDiaria: json['secuencia_diaria'] ?? 0,
      fecha: json['fecha'] ?? '',
      clienteNombre: json['cliente_nombre'] ?? '',
      clienteTelefono: json['cliente_telefono'] ?? '',
      direccion: json['direccion'],
      tipoEntrega: json['tipo_entrega'] ?? 'Recoger',
      estado: json['estado'] ?? 'Pendiente',
      total: double.parse((json['total'] ?? 0).toString()),
      nota: json['nota'],
      facturaId: json['factura_id'],
      codigoBarras: json['codigo_barras'],
      detalles: detallesList,
    );
  }
}
