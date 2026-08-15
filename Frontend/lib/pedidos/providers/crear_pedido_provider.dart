import 'package:flutter_riverpod/legacy.dart';
import '../../facturacion/models/factura_item.dart';

class CrearPedidoState {
  final List<FacturaItem> carrito;
  final String clienteNombre;
  final String clienteTelefono;
  final String direccion;
  final String tipoEntrega;
  final String nota;
  final bool isLoading;
  final String? error;

  CrearPedidoState({
    this.carrito = const [],
    this.clienteNombre = '',
    this.clienteTelefono = '',
    this.direccion = '',
    this.tipoEntrega = 'Delivery',
    this.nota = "",
    this.isLoading = false,
    this.error,
  });

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

  CrearPedidoState copyWith({
    List<FacturaItem>? carrito,
    String? clienteNombre,
    String? clienteTelefono,
    String? direccion,
    String? tipoEntrega,
    String? nota,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CrearPedidoState(
      carrito: carrito ?? this.carrito,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      direccion: direccion ?? this.direccion,
      tipoEntrega: tipoEntrega ?? this.tipoEntrega,
      nota: nota ?? this.nota,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CrearPedidoNotifier extends StateNotifier<CrearPedidoState> {
  CrearPedidoNotifier() : super(CrearPedidoState());

  void setClienteInfo({
    String? nombre,
    String? telefono,
    String? direccion,
    String? tipoEntrega,
    String? nota,
  }) {
    state = state.copyWith(
      clienteNombre: nombre,
      clienteTelefono: telefono,
      direccion: direccion,
      tipoEntrega: tipoEntrega,
      nota: nota,
    );
  }

  void agregarProducto(FacturaItem item) {
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

  void limpiarCarrito() {
    state = state.copyWith(carrito: []);
  }

  void resetState() {
    state = CrearPedidoState();
  }
}

final crearPedidoProvider =
    StateNotifierProvider<CrearPedidoNotifier, CrearPedidoState>((ref) {
      return CrearPedidoNotifier();
    });
