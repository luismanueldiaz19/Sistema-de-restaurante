import 'package:flutter_riverpod/legacy.dart';

class NuevaCompraDetalleItem {
  final int productoId;
  final String productoNombre;
  final double cantidad;
  final double costoUnitario;
  final double impuestoMonto;

  NuevaCompraDetalleItem({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.costoUnitario,
    required this.impuestoMonto,
  });

  double get subtotal => cantidad * costoUnitario;
  double get total => subtotal + impuestoMonto;

  double get costoUnitarioConItbis {
    if (cantidad <= 0) return costoUnitario;
    return (subtotal + impuestoMonto) / cantidad;
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'cantidad': cantidad,
      'costo_unitario': costoUnitario,
      'impuesto_monto': impuestoMonto,
    };
  }
}

class NuevaCompraFormState {
  final List<NuevaCompraDetalleItem> detalles;
  final String tipoCompra;
  final DateTime fechaCompra;
  final DateTime? fechaVencimiento;
  final String? proveedorId;
  final String ncf;
  final String numFactura;
  final String notas;

  NuevaCompraFormState({
    this.detalles = const [],
    this.tipoCompra = 'CONTADO',
    required this.fechaCompra,
    this.fechaVencimiento,
    this.proveedorId,
    this.ncf = '',
    this.numFactura = '',
    this.notas = '',
  });

  double get subtotal => detalles.fold(0, (sum, item) => sum + item.subtotal);

  double get impuestos =>
      detalles.fold(0, (sum, item) => sum + item.impuestoMonto);

  double get total => subtotal + impuestos;

  NuevaCompraFormState copyWith({
    List<NuevaCompraDetalleItem>? detalles,
    String? tipoCompra,
    DateTime? fechaCompra,
    DateTime? fechaVencimiento,
    String? proveedorId,
    bool clearProveedor = false,
    bool clearFechaVencimiento = false,
    String? ncf,
    String? numFactura,
    String? notas,
  }) {
    return NuevaCompraFormState(
      detalles: detalles ?? this.detalles,
      tipoCompra: tipoCompra ?? this.tipoCompra,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      fechaVencimiento: clearFechaVencimiento
          ? null
          : (fechaVencimiento ?? this.fechaVencimiento),
      proveedorId: clearProveedor ? null : (proveedorId ?? this.proveedorId),
      ncf: ncf ?? this.ncf,
      numFactura: numFactura ?? this.numFactura,
      notas: notas ?? this.notas,
    );
  }
}

class NuevaCompraFormNotifier extends StateNotifier<NuevaCompraFormState> {
  NuevaCompraFormNotifier()
    : super(NuevaCompraFormState(fechaCompra: DateTime.now()));

  void addDetalle(NuevaCompraDetalleItem detalle) {
    state = state.copyWith(detalles: [...state.detalles, detalle]);
  }

  void removeDetalle(int index) {
    final newList = List<NuevaCompraDetalleItem>.from(state.detalles);
    newList.removeAt(index);
    state = state.copyWith(detalles: newList);
  }

  void setProveedor(String? proveedorId) {
    state = state.copyWith(
      proveedorId: proveedorId,
      clearProveedor: proveedorId == null,
    );
  }

  void setTipoCompra(String tipo) {
    state = state.copyWith(tipoCompra: tipo);
  }

  void setFechaCompra(DateTime fecha) {
    state = state.copyWith(fechaCompra: fecha);
  }

  void setFechaVencimiento(DateTime? fecha) {
    state = state.copyWith(
      fechaVencimiento: fecha,
      clearFechaVencimiento: fecha == null,
    );
  }

  void setNcf(String ncf) {
    state = state.copyWith(ncf: ncf);
  }

  void setNumFactura(String numFactura) {
    state = state.copyWith(numFactura: numFactura);
  }

  void setNotas(String notas) {
    state = state.copyWith(notas: notas);
  }

  void clearForm() {
    state = NuevaCompraFormState(fechaCompra: DateTime.now());
  }
}

final nuevaCompraFormProvider =
    StateNotifierProvider<NuevaCompraFormNotifier, NuevaCompraFormState>((ref) {
      return NuevaCompraFormNotifier();
    });
