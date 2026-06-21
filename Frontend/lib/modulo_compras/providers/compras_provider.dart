import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/compra.dart';
import '../services/compra_api.dart';
import '../../providers/auth_provider.dart';

final compraApiProvider = Provider((ref) => CompraApi());

class TotalesCompras {
  final double totalPagado;
  final double totalPendiente;
  final double totalGeneral;

  TotalesCompras({
    this.totalPagado = 0,
    this.totalPendiente = 0,
    this.totalGeneral = 0,
  });
}

class ComprasState {
  final bool isLoading;
  final List<Compra> compras;
  final String? error;
  final TotalesCompras totales;

  ComprasState({
    this.isLoading = false,
    this.compras = const [],
    this.error,
    TotalesCompras? totales,
  }) : totales = totales ?? TotalesCompras();

  ComprasState copyWith({
    bool? isLoading,
    List<Compra>? compras,
    String? error,
    TotalesCompras? totales,
  }) {
    return ComprasState(
      isLoading: isLoading ?? this.isLoading,
      compras: compras ?? this.compras,
      error: error ?? this.error,
      totales: totales ?? this.totales,
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

  Future<void> loadCompras({String? fechaDesde, String? fechaHasta}) async {
    if (token == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await api.getAll(token!, fechaDesde: fechaDesde, fechaHasta: fechaHasta);
      final list = data.map((e) => Compra.fromJson(e)).toList();
      
      double pagado = 0;
      double pendiente = 0;
      
      for (var c in list) {
        if (c.estado == 'PAGADA') {
          pagado += c.total;
        } else {
          pendiente += c.total;
        }
      }
      
      state = state.copyWith(
        isLoading: false, 
        compras: list,
        totales: TotalesCompras(
          totalPagado: pagado,
          totalPendiente: pendiente,
          totalGeneral: pagado + pendiente,
        )
      );
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
