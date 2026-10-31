import 'package:flutter_riverpod/legacy.dart';
import '../services/caja_service.dart';

class CajaState {
  final bool isLoading;
  final Map<String, dynamic>? sesionActiva;
  final List<dynamic> historial;
  final String? errorMessage;
  final Map<String, String> filters;

  final Map<String, dynamic>? resumenSesion;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final String searchQuery;

  CajaState({
    this.isLoading = false,
    this.sesionActiva,
    this.resumenSesion,
    this.historial = const [],
    this.errorMessage,
    this.filters = const {},
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
    this.searchQuery = '',
  });

  CajaState copyWith({
    bool? isLoading,
    Map<String, dynamic>? sesionActiva,
    bool clearSesion = false,
    List<dynamic>? historial,
    String? errorMessage,
    Map<String, dynamic>? resumenSesion,
    bool clearResumen = false,
    Map<String, String>? filters,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
    String? searchQuery,
  }) {
    return CajaState(
      isLoading: isLoading ?? this.isLoading,
      sesionActiva: clearSesion ? null : (sesionActiva ?? this.sesionActiva),
      resumenSesion: clearResumen
          ? null
          : (resumenSesion ?? this.resumenSesion),
      historial: historial ?? this.historial,
      errorMessage: errorMessage,
      filters: filters ?? this.filters,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CajaNotifier extends StateNotifier<CajaState> {
  final CajaService _service = CajaService();

  CajaNotifier() : super(CajaState());

  Future<void> checkEstado(String token) async {
    state = state.copyWith(isLoading: true);
    final result = await _service.getEstadoCaja(token);

    if (!mounted) return;

    if (result['success']) {
      state = state.copyWith(isLoading: false, sesionActiva: result['data']);
      if (result['data'] != null) {
        fetchResumen(token);
      }
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result['message']);
    }
  }

  Future<void> fetchResumen(String token) async {
    final result = await _service.getResumenCierre(token);

    if (!mounted) return;

    if (result['success']) {
      state = state.copyWith(resumenSesion: result['data']);
    }
  }

  Future<Map<String, dynamic>> getResumen(String token) async {
    return await _service.getResumenCierre(token);
  }

  Future<Map<String, dynamic>> cerrarCaja({
    required String token,
    required double montoFisico,
    required Map<String, int> desglose,
    String? comentario,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _service.cerrarCaja(
      token: token,
      montoFisico: montoFisico,
      desglose: desglose,
      comentario: comentario,
    );

    if (!mounted) return result;

    if (result['success']) {
      state = state.copyWith(
        isLoading: false,
        clearSesion: true,
        clearResumen: true,
      );
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result['message']);
    }
    return result;
  }

  Future<String?> abrirCaja({
    required String token,
    required int cajaId,
    required int turnoId,
    required double montoInicial,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _service.abrirCaja(
      token: token,
      cajaId: cajaId,
      turnoId: turnoId,
      montoInicial: montoInicial,
    );

    if (!mounted) return result['success'] ? null : result['message'];

    if (result['success']) {
      state = state.copyWith(isLoading: false, sesionActiva: result['data']);
      return null; // Éxito
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result['message']);
      return result['message'];
    }
  }

  Future<void> fetchHistorial(String token, {int page = 1}) async {
    state = state.copyWith(isLoading: true);
    final queryParams = Map<String, String>.from(state.filters);
    if (page > 1) {
      queryParams['page'] = page.toString();
    }
    if (state.searchQuery.trim().isNotEmpty) {
      queryParams['search'] = state.searchQuery.trim();
    }

    final result = await _service.getHistorial(
      token: token,
      filters: queryParams,
    );

    if (!mounted) return;

    if (result['success']) {
      final pData = result['data'];
      final List<dynamic> list = pData is Map ? (pData['data'] ?? []) : (pData is List ? pData : []);
      final int current = pData is Map ? (pData['current_page'] ?? page) : 1;
      final int last = pData is Map ? (pData['last_page'] ?? 1) : 1;
      final int total = pData is Map ? (pData['total'] ?? list.length) : list.length;

      state = state.copyWith(
        isLoading: false,
        historial: list,
        currentPage: current,
        totalPages: last,
        totalRecords: total,
      );
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result['message']);
    }
  }

  void searchHistorial(String query, String token) {
    state = state.copyWith(searchQuery: query);
    fetchHistorial(token, page: 1);
  }

  void updateFilters(
    String token,
    Map<String, String> newFilters, {
    bool replace = false,
  }) {
    state = state.copyWith(
      filters: replace ? newFilters : {...state.filters, ...newFilters},
    );
    fetchHistorial(token, page: 1);
  }

  void clearFilters(String token) {
    state = state.copyWith(filters: {}, searchQuery: '');
    fetchHistorial(token, page: 1);
  }
}

final cajaProvider = StateNotifierProvider<CajaNotifier, CajaState>((ref) {
  return CajaNotifier();
});
