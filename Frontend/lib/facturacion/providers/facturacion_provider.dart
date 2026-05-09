import 'package:flutter_riverpod/legacy.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../models/factura_item.dart';
import '../../model/comprobante.dart';

class FacturacionState {
  final List<FacturaItem> carrito;
  final Cliente? clienteSeleccionado;
  final Comprobante? comprobanteSeleccionado;
  final String tipoFactura; // 'contado' o 'credito'
  final int diasCredito;
  final String nota;
  final bool isLoading;
  final String? error;

  FacturacionState({
    this.carrito = const [],
    this.clienteSeleccionado,
    this.comprobanteSeleccionado,
    this.tipoFactura = 'contado',
    this.diasCredito = 0,
    this.nota = "",
    this.isLoading = false,
    this.error,
  });

  // Cálculos consolidados para la UI
  TotalesFactura get totales {
    double sub = 0;
    double desc = 0;
    double tax = 0;
    double total = 0;

    for (var item in carrito) {
      sub += item.subtotal;
      desc += item.montoDescuento;
      tax += item.montoItbis;
      total += item.total;
    }

    return TotalesFactura(
      subtotal: sub,
      descuento: desc,
      itbis: tax,
      total: total,
    );
  }

  FacturacionState copyWith({
    List<FacturaItem>? carrito,
    Cliente? clienteSeleccionado,
    bool clearCliente = false,
    Comprobante? comprobanteSeleccionado,
    bool clearComprobante = false,
    String? tipoFactura,
    int? diasCredito,
    String? nota,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FacturacionState(
      carrito: carrito ?? this.carrito,
      clienteSeleccionado: clearCliente
          ? null
          : (clienteSeleccionado ?? this.clienteSeleccionado),
      comprobanteSeleccionado: clearComprobante
          ? null
          : (comprobanteSeleccionado ?? this.comprobanteSeleccionado),
      tipoFactura: tipoFactura ?? this.tipoFactura,
      diasCredito: diasCredito ?? this.diasCredito,
      nota: nota ?? this.nota,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FacturacionNotifier extends StateNotifier<FacturacionState> {
  FacturacionNotifier() : super(FacturacionState());

  void seleccionarCliente(Cliente cliente) {
    state = state.copyWith(
      clienteSeleccionado: cliente,
      diasCredito: cliente.diasCredito ?? 0,
      tipoFactura: (cliente.diasCredito ?? 0) > 0 ? 'credito' : 'contado',
    );
  }

  void seleccionarComprobante(Comprobante comprobante) {
    state = state.copyWith(comprobanteSeleccionado: comprobante);
  }

  void cambiarTipoFactura(String tipo) {
    state = state.copyWith(tipoFactura: tipo);
  }

  void cambiarDiasCredito(int dias) {
    state = state.copyWith(diasCredito: dias);
  }

  void cambiarNota(String nota) {
    state = state.copyWith(nota: nota);
  }

  void agregarProducto(FacturaItem item) {
    // Si ya existe, aumentar cantidad
    final index = state.carrito.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      final updatedCarrito = List<FacturaItem>.from(state.carrito);
      final existingItem = updatedCarrito[index];
      updatedCarrito[index] = existingItem.copyWith(
        cantidad: existingItem.cantidad + 1,
      );
      state = state.copyWith(carrito: updatedCarrito);
    } else {
      state = state.copyWith(carrito: [item, ...state.carrito]);
    }
  }

  void removerProducto(String id) {
    state = state.copyWith(
      carrito: state.carrito.where((item) => item.id != id).toList(),
    );
  }

  void actualizarCantidad(String id, double cantidad) {
    state = state.copyWith(
      carrito: state.carrito.map((item) {
        return item.id == id ? item.copyWith(cantidad: cantidad) : item;
      }).toList(),
    );
  }

  void actualizarDescuento(String id, double porcentaje) {
    state = state.copyWith(
      carrito: state.carrito.map((item) {
        return item.id == id
            ? item.copyWith(descuentoPorcentaje: porcentaje)
            : item;
      }).toList(),
    );
  }

  void limpiarCarrito() {
    state = state.copyWith(carrito: []);
  }

  void resetState() {
    state = FacturacionState();
  }
}

final facturacionProvider =
    StateNotifierProvider<FacturacionNotifier, FacturacionState>((ref) {
      return FacturacionNotifier();
    });
