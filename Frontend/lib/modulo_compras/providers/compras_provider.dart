import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/compra.dart';
import '../services/compra_api.dart';
import '../../providers/auth_provider.dart';

final compraApiProvider = Provider((ref) => CompraApi());

class ComprasState {
  final bool isLoading;
  final List<Compra> compras;
  final String? error;

  ComprasState({this.isLoading = false, this.compras = const [], this.error});

  ComprasState copyWith({
    bool? isLoading,
    List<Compra>? compras,
    String? error,
  }) {
    return ComprasState(
      isLoading: isLoading ?? this.isLoading,
      compras: compras ?? this.compras,
      error: error ?? this.error,
    );
  }
}

class ComprasNotifier extends StateNotifier<ComprasState> {
  final CompraApi api;
  final String? token;

  ComprasNotifier(this.api, this.token) : super(ComprasState()) {
    if (token != null) {
      loadCompras();
    }
  }

  Future<void> loadCompras() async {
    if (token == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await api.getAll(token!);
      final list = data.map((e) => Compra.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, compras: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createCompra(Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await api.create(token!, data);
      await loadCompras();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final comprasProvider = StateNotifierProvider<ComprasNotifier, ComprasState>((
  ref,
) {
  final api = ref.watch(compraApiProvider);
  final token = ref.watch(authProvider).token;
  return ComprasNotifier(api, token);
});
