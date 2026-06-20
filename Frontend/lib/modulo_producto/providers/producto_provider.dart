import 'package:flutter_riverpod/legacy.dart';
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

  Future<void> loadProductos(String token, {bool silent = false}) async {
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
    if (query.isEmpty) {
      state = state.copyWith(productos: _allProductos);
    } else {
      final q = query.toLowerCase();
      final filtered = _allProductos.where((p) {
        return (p.nombre?.toLowerCase().contains(q) ?? false) ||
            (p.codigo?.toLowerCase().contains(q) ?? false) ||
            (p.categoria?.nombre.toLowerCase().contains(q) ?? false);
      }).toList();
      state = state.copyWith(productos: filtered);
    }
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

  Future<String> importProductos(List<int> bytes, String filename, String token) async {
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
