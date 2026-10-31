import 'package:flutter_riverpod/legacy.dart';
import '../models/producto.dart';
import '../services/receta_api.dart';
import 'receta_state.dart';

final recetaProvider = StateNotifierProvider<RecetaNotifier, RecetaState>((
  ref,
) {
  return RecetaNotifier();
});

class RecetaNotifier extends StateNotifier<RecetaState> {
  RecetaNotifier() : super(RecetaState());

  final _api = RecetaApi();

  Future<List<Producto>> loadProductosConRecetas(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _api.fetchProductosConRecetas(token);
      state = state.copyWith(isLoading: false);
      return results;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  Future<bool> saveReceta(
    String productoId,
    List<Map<String, dynamic>> ingredientes,
    String token,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.updateReceta(productoId, ingredientes, token);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
