import '../models/producto.dart';

class ProductoState {
  final List<Producto> productos;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalRecords;

  ProductoState({
    this.productos = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
  });

  ProductoState copyWith({
    List<Producto>? productos,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
  }) {
    return ProductoState(
      productos: productos ?? this.productos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
    );
  }
}
