import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/pago_compra.dart';
import '../services/cxp_api.dart';
import '../../providers/auth_provider.dart';

final cxpApiProvider = Provider((ref) => CxpApi());

final historialPagosComprasProvider =
    StateNotifierProvider<
      HistorialPagosComprasNotifier,
      HistorialPagosComprasState
    >((ref) {
      final auth = ref.watch(authProvider);
      final api = ref.read(cxpApiProvider);
      return HistorialPagosComprasNotifier(api, auth.token);
    });

class HistorialPagosComprasState {
  final bool isLoading;
  final List<PagoCompra> pagos;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  final Map<String, dynamic> filters;

  HistorialPagosComprasState({
    this.isLoading = false,
    this.pagos = const [],
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.filters = const {},
  });

  HistorialPagosComprasState copyWith({
    bool? isLoading,
    List<PagoCompra>? pagos,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    Map<String, dynamic>? filters,
  }) {
    return HistorialPagosComprasState(
      isLoading: isLoading ?? this.isLoading,
      pagos: pagos ?? this.pagos,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      filters: filters ?? this.filters,
    );
  }
}

class HistorialPagosComprasNotifier
    extends StateNotifier<HistorialPagosComprasState> {
  final CxpApi api;
  final String? token;

  HistorialPagosComprasNotifier(this.api, this.token)
    : super(HistorialPagosComprasState()) {
    if (token != null) {
      loadPagos();
    }
  }

  void updateFilters(Map<String, dynamic> newFilters) {
    state = state.copyWith(
      filters: newFilters,
      currentPage: 1,
    );
    loadPagos();
  }

  void clearFilters() {
    state = state.copyWith(filters: {}, currentPage: 1);
    loadPagos();
  }

  void changePage(int page) {
    if (page > 0 && page <= state.lastPage) {
      state = state.copyWith(currentPage: page);
      loadPagos();
    }
  }

  Future<void> loadPagos() async {
    if (token == null) return;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final filters = {
        ...state.filters,
        'page': state.currentPage,
        'per_page': 15,
      };
      final data = await api.getHistorialPagos(token!, filters: filters);

      final listData = data['data'] as List<dynamic>? ?? [];
      final pagos = listData
          .map((e) => PagoCompra.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        pagos: pagos,
        currentPage: data['current_page'] ?? 1,
        lastPage: data['last_page'] ?? 1,
        total: data['total'] ?? 0,
        error: '',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
