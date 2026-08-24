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
  List<Producto> _allProductos = [];

  Future<void> loadProductos(String token, {bool silent = false, bool forceRefresh = false}) async {
    if (!forceRefresh && _allProductos.isNotEmpty) return;

    if (!silent) state = state.copyWith(isLoading: true);
    try {
      final results = await _api.fetchProductos(token);
      results.sort(
        (a, b) => (a.nombre ?? '').toLowerCase().compareTo(
          (b.nombre ?? '').toLowerCase(),
        ),
      );
      _allProductos = results;
      state = state.copyWith(productos: _allProductos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void searchProductos(String query) {
    final normalizedQuery = TextNormalizer.normalizar(query);
    final productos = normalizedQuery.isEmpty
        ? _allProductos
        : _allProductos
              .where(
                (producto) => producto.searchIndex.contains(normalizedQuery),
              )
              .toList();
    state = state.copyWith(productos: productos);
  }

  Future<bool> createProducto(Map<String, dynamic> data, String token) async {
    state = state.copyWith(isLoading: true);
    try {
      final newItem = await _api.createProducto(data, token);
      _allProductos = [..._allProductos, newItem];
      state = state.copyWith(productos: _allProductos, isLoading: false);
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
      _allProductos = _allProductos
          .map((p) => p.id.toString() == id ? updatedItem : p)
          .toList();
      state = state.copyWith(productos: _allProductos, isLoading: false);
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
        _allProductos = _allProductos.where((p) => p.id != id).toList();
        state = state.copyWith(productos: _allProductos, isLoading: false);
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
      await loadProductos(token, silent: true);
      return message;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw e;
    }
  }
}
