import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/cotizacion_model.dart';
import '../services/cotizacion_service.dart';

class CotizacionHistorialState {
  final List<Cotizacion> historial;
  final bool isLoading;
  final String? error;
  final Map<String, String> filters;
  final Map<String, dynamic>? resumen;

  CotizacionHistorialState({
    this.historial = const [],
    this.isLoading = false,
    this.error,
    this.filters = const {},
    this.resumen,
  });

  Map<String, double> get totales {
    double subtotal = 0;
    double itbis = 0;
    double descuento = 0;
    double total = 0;

    for (var f in historial) {
      if (f.estado != 'cancelado') {
        subtotal += double.tryParse(f.subtotal ?? '0') ?? 0;
        itbis += double.tryParse(f.itbis ?? '0') ?? 0;
        descuento += double.tryParse(f.descuentoTotal ?? '0') ?? 0;
        total += double.tryParse(f.total ?? '0') ?? 0;
      }
    }

    return {
      'subtotal': subtotal,
      'itbis': itbis,
      'descuento': descuento,
      'total': total,
    };
  }

  CotizacionHistorialState copyWith({
    List<Cotizacion>? historial,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, String>? filters,
    Map<String, dynamic>? resumen,
  }) {
    return CotizacionHistorialState(
      historial: historial ?? this.historial,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      resumen: resumen ?? this.resumen,
    );
  }
}

class CotizacionHistorialNotifier extends StateNotifier<CotizacionHistorialState> {
  final CotizacionService _service = CotizacionService();

  CotizacionHistorialNotifier() : super(CotizacionHistorialState());

  Future<void> fetchHistorial(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.getHistorial(
      token: token,
      filters: state.filters,
    );

    if (result['success']) {
      final List<dynamic> data = result['data']['data'] ?? [];
      final List<Cotizacion> cotizaciones = data.map((json) => Cotizacion.fromJson(json)).toList();
      state = state.copyWith(
        isLoading: false,
        historial: cotizaciones,
        resumen: result['resumen'],
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'],
      );
    }
  }

  void updateFilters(String token, Map<String, String> newFilters, {bool replace = false}) {
    state = state.copyWith(filters: replace ? newFilters : {...state.filters, ...newFilters});
    fetchHistorial(token);
  }

  void clearFilters(String token) {
    state = state.copyWith(filters: {});
    fetchHistorial(token);
  }

  Future<bool> updateEstado(String token, String id, String estado) async {
    final result = await _service.updateEstado(id: id, estado: estado, token: token);
    if (result['success']) {
      fetchHistorial(token);
      return true;
    }
    return false;
  }
}

final cotizacionHistorialProvider =
    StateNotifierProvider<CotizacionHistorialNotifier, CotizacionHistorialState>((ref) {
  return CotizacionHistorialNotifier();
});
