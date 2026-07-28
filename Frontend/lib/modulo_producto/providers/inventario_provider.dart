import 'package:flutter_riverpod/legacy.dart';
import '../models/movimiento_inventario.dart';
import '../services/inventario_api.dart';

class InventarioState {
  final bool isLoading;
  final String? error;
  final List<MovimientoInventario> movimientos;

  InventarioState({
    this.isLoading = false,
    this.error,
    this.movimientos = const [],
  });

  InventarioState copyWith({
    bool? isLoading,
    String? error,
    List<MovimientoInventario>? movimientos,
  }) {
    return InventarioState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      movimientos: movimientos ?? this.movimientos,
    );
  }
}

final inventarioProvider = StateNotifierProvider<InventarioNotifier, InventarioState>((ref) {
  return InventarioNotifier();
});

class InventarioNotifier extends StateNotifier<InventarioState> {
  InventarioNotifier() : super(InventarioState());

  final _api = InventarioApi();

  Future<void> loadMovimientos(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final movimientos = await _api.fetchMovimientos(token);
      state = state.copyWith(isLoading: false, movimientos: movimientos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> registrarAjuste(
    int productoId,
    String tipo,
    double cantidad,
    String motivo,
    String token,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.registrarAjuste(productoId, tipo, cantidad, motivo, token);
      await loadMovimientos(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
