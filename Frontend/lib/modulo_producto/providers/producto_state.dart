import '../models/producto.dart';

class ProductoState {
  final List<Producto> productos;
  final bool isLoading;
  final String? error;

  ProductoState({
    this.productos = const [],
    this.isLoading = false,
    this.error,
  });

  ProductoState copyWith({
    List<Producto>? productos,
    bool? isLoading,
    String? error,
  }) {
    return ProductoState(
      productos: productos ?? this.productos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
