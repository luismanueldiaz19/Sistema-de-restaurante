import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../../facturacion/models/factura_item.dart';
import '../services/cotizacion_service.dart';

class CotizacionFormState {
  final List<FacturaItem> carrito;
  final Cliente? clienteSeleccionado;
  final int diasValidez;
  final String nota;
  final bool isLoading;
  final String? error;

  CotizacionFormState({
    this.carrito = const [],
    this.clienteSeleccionado,
    this.diasValidez = 15,
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

  CotizacionFormState copyWith({
    List<FacturaItem>? carrito,
    Cliente? clienteSeleccionado,
    bool clearCliente = false,
    int? diasValidez,
    String? nota,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CotizacionFormState(
      carrito: carrito ?? this.carrito,
      clienteSeleccionado: clearCliente
          ? null
          : (clienteSeleccionado ?? this.clienteSeleccionado),
      diasValidez: diasValidez ?? this.diasValidez,
      nota: nota ?? this.nota,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CotizacionFormNotifier extends StateNotifier<CotizacionFormState> {
  final CotizacionService _service = CotizacionService();

  CotizacionFormNotifier() : super(CotizacionFormState());

  void seleccionarCliente(Cliente cliente) {
    state = state.copyWith(clienteSeleccionado: cliente);
  }

  void cambiarDiasValidez(int dias) {
    state = state.copyWith(diasValidez: dias);
  }

  void cambiarNota(String nota) {
    state = state.copyWith(nota: nota);
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
    state = CotizacionFormState();
  }

  Future<Map<String, dynamic>> crearCotizacion(String token) async {
    if (state.clienteSeleccionado == null || state.carrito.isEmpty) {
      return {'success': false, 'message': 'Complete todos los campos'};
    }

    state = state.copyWith(isLoading: true);

    final result = await _service.crearCotizacion(
      cliente: state.clienteSeleccionado!,
      items: state.carrito,
      token: token,
      nota: state.nota,
      diasValidez: state.diasValidez,
    );

    state = state.copyWith(isLoading: false);
    return result;
  }
}

final cotizacionFormProvider =
    StateNotifierProvider<CotizacionFormNotifier, CotizacionFormState>((ref) {
      return CotizacionFormNotifier();
    });
