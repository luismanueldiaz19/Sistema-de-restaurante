import '../models/producto.dart';

class ProductoState {
  final List<Producto> productos;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final String searchQuery;
  final int? categoriaId;
  final int? marcaId;
  final String? tipoProducto;

  ProductoState({
    this.productos = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
    this.searchQuery = '',
    this.categoriaId,
    this.marcaId,
    this.tipoProducto,
  });

  ProductoState copyWith({
    List<Producto>? productos,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
    String? searchQuery,
    int? categoriaId,
    int? marcaId,
    String? tipoProducto,
  }) {
    return ProductoState(
      productos: productos ?? this.productos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
      searchQuery: searchQuery ?? this.searchQuery,
      categoriaId: categoriaId != null ? (categoriaId == -1 ? null : categoriaId) : this.categoriaId,
      marcaId: marcaId != null ? (marcaId == -1 ? null : marcaId) : this.marcaId,
      tipoProducto: tipoProducto != null ? (tipoProducto == '' ? null : tipoProducto) : this.tipoProducto,
    );
  }
}
