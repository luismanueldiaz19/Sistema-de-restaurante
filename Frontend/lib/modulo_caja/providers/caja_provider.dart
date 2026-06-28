import 'package:flutter_riverpod/legacy.dart';
import '../services/caja_service.dart';

class CajaState {
  final bool isLoading;
  final Map<String, dynamic>? sesionActiva;
  final List<dynamic> historial;
  final String? errorMessage;
  final Map<String, String> filters;

  final Map<String, dynamic>? resumenSesion;

  CajaState({
    this.isLoading = false,
    this.sesionActiva,
    this.resumenSesion,
    this.historial = const [],
    this.errorMessage,
    this.filters = const {},
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

  Future<void> fetchHistorial(String token) async {
    state = state.copyWith(isLoading: true);
    final result = await _service.getHistorial(
      token: token,
      filters: state.filters,
    );

    if (!mounted) return;

    if (result['success']) {
      state = state.copyWith(
        isLoading: false,
        historial: result['data']['data'] ?? [],
      );
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result['message']);
    }
  }

  void updateFilters(
    String token,
    Map<String, String> newFilters, {
    bool replace = false,
  }) {
    state = state.copyWith(
      filters: replace ? newFilters : {...state.filters, ...newFilters},
    );
    fetchHistorial(token);
  }

  void clearFilters(String token) {
    state = state.copyWith(filters: {});
    fetchHistorial(token);
  }
}

final cajaProvider = StateNotifierProvider<CajaNotifier, CajaState>((ref) {
  return CajaNotifier();
});
