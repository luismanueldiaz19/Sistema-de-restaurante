import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../model/factura.dart';
import '../services/facturacion_service.dart';

class FacturacionHistorialState {
  final List<Factura> historial;
  final bool isLoading;
  final String? error;
  final Map<String, String> filters;

  final Map<String, dynamic>? resumen;

  FacturacionHistorialState({
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
      if (f.estado != 'anulada') {
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

  FacturacionHistorialState copyWith({
    List<Factura>? historial,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, String>? filters,
    Map<String, dynamic>? resumen,
  }) {
    return FacturacionHistorialState(
      historial: historial ?? this.historial,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      resumen: resumen ?? this.resumen,
    );
  }
}

class FacturacionHistorialNotifier extends StateNotifier<FacturacionHistorialState> {
  final FacturacionService _service = FacturacionService();

  FacturacionHistorialNotifier() : super(FacturacionHistorialState());

  Future<void> fetchHistorial(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.getHistorial(
      token: token,
      filters: state.filters,
    );

    if (result['success']) {
      final List<dynamic> data = result['data']['data'] ?? [];
      final List<Factura> facturas = data.map((json) => Factura.fromJson(json)).toList();
      state = state.copyWith(
        isLoading: false,
        historial: facturas,
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

  Future<int?> generarNotaCredito(
    String token,
    int facturaId,
    List<Map<String, dynamic>> detalles,
    String motivo,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final id = await _service.generarNotaCredito(token, facturaId, detalles, motivo);
      await fetchHistorial(token);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final facturacionHistorialProvider =
    StateNotifierProvider<FacturacionHistorialNotifier, FacturacionHistorialState>((ref) {
  return FacturacionHistorialNotifier();
});
