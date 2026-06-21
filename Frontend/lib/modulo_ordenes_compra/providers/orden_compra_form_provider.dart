import 'package:flutter_riverpod/legacy.dart';
import '../../facturacion/models/factura_item.dart';
import '../../modulo_compras/models/proveedor.dart';
import '../services/orden_compra_service.dart';

class OrdenCompraFormState {
  final List<FacturaItem> carrito;
  final Proveedor? proveedorSeleccionado;
  final int diasValidez;
  final String nota;
  final bool isLoading;
  final String? error;

  OrdenCompraFormState({
    this.carrito = const [],
    this.proveedorSeleccionado,
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

  OrdenCompraFormState copyWith({
    List<FacturaItem>? carrito,
    Proveedor? proveedorSeleccionado,
    bool clearProveedor = false,
    int? diasValidez,
    String? nota,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OrdenCompraFormState(
      carrito: carrito ?? this.carrito,
      proveedorSeleccionado: clearProveedor
          ? null
          : (proveedorSeleccionado ?? this.proveedorSeleccionado),
      diasValidez: diasValidez ?? this.diasValidez,
      nota: nota ?? this.nota,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrdenCompraFormNotifier extends StateNotifier<OrdenCompraFormState> {
  final OrdenCompraService _service = OrdenCompraService();

  OrdenCompraFormNotifier() : super(OrdenCompraFormState());

  void seleccionarProveedor(Proveedor proveedor) {
    state = state.copyWith(proveedorSeleccionado: proveedor);
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

  void actualizarPrecio(String id, double precio) {
    state = state.copyWith(
      carrito: state.carrito.map((item) {
        return item.id == id ? item.copyWith(precio: precio) : item;
      }).toList(),
    );
  }

  void limpiarCarrito() {
    state = state.copyWith(carrito: []);
  }

  void resetState() {
    state = OrdenCompraFormState();
  }

  Future<Map<String, dynamic>> crearOrdenCompra(String token) async {
    if (state.proveedorSeleccionado == null || state.carrito.isEmpty) {
      return {'success': false, 'message': 'Complete todos los campos'};
    }

    state = state.copyWith(isLoading: true);

    final result = await _service.crearOrdenCompra(
      proveedor: state.proveedorSeleccionado!,
      items: state.carrito,
      token: token,
      nota: state.nota,
      diasValidez: state.diasValidez,
    );

    state = state.copyWith(isLoading: false);
    return result;
  }
}

final ordenCompraFormProvider =
    StateNotifierProvider<OrdenCompraFormNotifier, OrdenCompraFormState>((ref) {
      return OrdenCompraFormNotifier();
    });
