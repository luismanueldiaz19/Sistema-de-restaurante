import 'package:flutter_riverpod/legacy.dart';
import '../../utils/normalize.dart';
import '../models/producto.dart';
import '../services/producto_api.dart';
import 'producto_state.dart';

final productoProvider = StateNotifierProvider<ProductoNotifier, ProductoState>(
  (ref) {
    return ProductoNotifier();
  },
);

class ProductoNotifier extends StateNotifier<ProductoState> {
  ProductoNotifier() : super(ProductoState());

  final _api = ProductoApi();
  Future<void> loadProductos(
    String token, {
    int page = 1,
    bool silent = false,
    required String search,
  }) async {
    if (!silent) state = state.copyWith(isLoading: true);
    try {
      final response = await _api.fetchProductos(
        token,
        page: page,
        search: state.searchQuery,
        categoriaId: state.categoriaId,
        marcaId: state.marcaId,
        tipoProducto: state.tipoProducto,
      );
      final List<Producto> resultados = response['productos'];

      state = state.copyWith(
        productos: resultados,
        isLoading: false,
        currentPage: response['currentPage'],
        totalPages: response['totalPages'],
        totalRecords: response['totalRecords'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void searchProductos(String query, String token) {
    state = state.copyWith(searchQuery: query);
    loadProductos(token, page: 1, silent: true, search: '');
  }

  void setCategoriaFilter(int? id, String token) {
    state = state.copyWith(categoriaId: id ?? -1); // -1 means clear
    loadProductos(token, page: 1, silent: true, search: '');
  }

  void setMarcaFilter(int? id, String token) {
    state = state.copyWith(marcaId: id ?? -1);
    loadProductos(token, page: 1, silent: true, search: '');
  }

  void setTipoProductoFilter(String? tipo, String token) {
    state = state.copyWith(tipoProducto: tipo ?? ''); // '' means clear
    loadProductos(token, page: 1, silent: true, search: '');
  }

  Future<bool> createProducto(Map<String, dynamic> data, String token) async {
    state = state.copyWith(isLoading: true);
    try {
      final newItem = await _api.createProducto(data, token);
      final currentList = [newItem, ...state.productos];
      state = state.copyWith(
        productos: currentList,
        isLoading: false,
        totalRecords: state.totalRecords + 1,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProducto(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedItem = await _api.updateProducto(id, data, token);
      final currentList = state.productos
          .map((p) => p.id.toString() == id ? updatedItem : p)
          .toList();
      state = state.copyWith(productos: currentList, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProducto(int id, String token) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _api.deleteProducto(id, token);
      if (success) {
        final currentList = state.productos.where((p) => p.id != id).toList();
        state = state.copyWith(
          productos: currentList,
          isLoading: false,
          totalRecords: state.totalRecords - 1,
        );
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<String> importProductos(
    List<int> bytes,
    String filename,
    String token,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      final message = await _api.importProductos(bytes, filename, token);
      await loadProductos(token, silent: true, search: '');
      return message;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw e;
    }
  }
}
