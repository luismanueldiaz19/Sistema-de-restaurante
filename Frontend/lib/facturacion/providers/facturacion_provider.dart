import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../models/factura_item.dart';
import '../../model/comprobante.dart';

class FacturacionState {
  final List<FacturaItem> carrito;
  final Cliente? clienteSeleccionado;
  final Comprobante? comprobanteSeleccionado;
  final bool isLoading;
  final String? error;

  FacturacionState({
    this.carrito = const [],
    this.clienteSeleccionado,
    this.comprobanteSeleccionado,
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
    Comprobante? comprobanteSeleccionado,
    bool? isLoading,
    String? error,
  }) {
    return FacturacionState(
      carrito: carrito ?? this.carrito,
      clienteSeleccionado: clienteSeleccionado ?? this.clienteSeleccionado,
      comprobanteSeleccionado:
          comprobanteSeleccionado ?? this.comprobanteSeleccionado,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FacturacionNotifier extends StateNotifier<FacturacionState> {
  FacturacionNotifier() : super(FacturacionState());

  void seleccionarCliente(Cliente cliente) {
    state = state.copyWith(clienteSeleccionado: cliente);
  }

  void seleccionarComprobante(Comprobante comprobante) {
    state = state.copyWith(comprobanteSeleccionado: comprobante);
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
      state = state.copyWith(carrito: [...state.carrito, item]);
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
}

final facturacionProvider =
    StateNotifierProvider<FacturacionNotifier, FacturacionState>((ref) {
      return FacturacionNotifier();
    });
