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
  
  // Paginación
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  // Filtros
  final String? fechaDesde;
  final String? fechaHasta;
  final String? estado;
  final String? search;

  ComprasState({
    this.isLoading = false,
    this.compras = const [],
    this.error,
    TotalesCompras? totales,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = true,
    this.fechaDesde,
    this.fechaHasta,
    this.estado = 'todos',
    this.search = '',
  }) : totales = totales ?? TotalesCompras();

  ComprasState copyWith({
    bool? isLoading,
    List<Compra>? compras,
    String? error,
    TotalesCompras? totales,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? search,
  }) {
    return ComprasState(
      isLoading: isLoading ?? this.isLoading,
      compras: compras ?? this.compras,
      error: error ?? this.error,
      totales: totales ?? this.totales,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasMore: hasMore ?? this.hasMore,
      fechaDesde: fechaDesde ?? this.fechaDesde,
      fechaHasta: fechaHasta ?? this.fechaHasta,
      estado: estado ?? this.estado,
      search: search ?? this.search,
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

  Future<void> loadCompras({
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? search,
    bool isRefresh = false,
  }) async {
    if (token == null) return;
    
    if (isRefresh) {
      state = state.copyWith(isLoading: true, error: null, currentPage: 1, hasMore: true);
    } else {
      state = state.copyWith(
        isLoading: true,
        error: null,
        fechaDesde: fechaDesde ?? state.fechaDesde,
        fechaHasta: fechaHasta ?? state.fechaHasta,
        estado: estado ?? state.estado,
        search: search ?? state.search,
        currentPage: 1,
        hasMore: true,
      );
    }

    try {
      final response = await api.getAll(
        token!,
        fechaDesde: state.fechaDesde,
        fechaHasta: state.fechaHasta,
        estado: state.estado,
        search: state.search,
        page: 1,
      );
      
      final List<dynamic> dataList = response['data'] ?? [];
      final list = dataList.map((e) => Compra.fromJson(e)).toList();

      final current = response['current_page'] ?? 1;
      final last = response['last_page'] ?? 1;

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
        currentPage: current,
        lastPage: last,
        hasMore: current < last,
        totales: TotalesCompras(
          totalPagado: pagado,
          totalPendiente: pendiente,
          totalGeneral: pagado + pendiente,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (token == null || state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await api.getAll(
        token!,
        fechaDesde: state.fechaDesde,
        fechaHasta: state.fechaHasta,
        estado: state.estado,
        search: state.search,
        page: nextPage,
      );

      final List<dynamic> dataList = response['data'] ?? [];
      final newItems = dataList.map((e) => Compra.fromJson(e)).toList();

      final current = response['current_page'] ?? nextPage;
      final last = response['last_page'] ?? nextPage;

      final allItems = [...state.compras, ...newItems];

      double pagado = 0;
      double pendiente = 0;
      for (var c in allItems) {
        if (c.estado == 'PAGADA') {
          pagado += c.total;
        } else {
          pendiente += c.total;
        }
      }

      state = state.copyWith(
        isLoading: false,
        compras: allItems,
        currentPage: current,
        lastPage: last,
        hasMore: current < last,
        totales: TotalesCompras(
          totalPagado: pagado,
          totalPendiente: pendiente,
          totalGeneral: pagado + pendiente,
        ),
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
