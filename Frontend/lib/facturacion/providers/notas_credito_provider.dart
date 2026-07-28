import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../model/nota_credito_model.dart';
import '../services/facturacion_service.dart';

class NotasCreditoState {
  final List<NotaCreditoModel> historial;
  final bool isLoading;
  final String? error;
  final Map<String, String> filters;
  final Map<String, dynamic>? resumen;

  NotasCreditoState({
    this.historial = const [],
    this.isLoading = false,
    this.error,
    this.filters = const {},
    this.resumen,
  });

  Map<String, double> get totales {
    double total = 0;
    for (var nc in historial) {
      total += double.tryParse(nc.totalDevolucion ?? '0') ?? 0;
    }
    return {
      'total': total,
    };
  }

  NotasCreditoState copyWith({
    List<NotaCreditoModel>? historial,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, String>? filters,
    Map<String, dynamic>? resumen,
  }) {
    return NotasCreditoState(
      historial: historial ?? this.historial,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      resumen: resumen ?? this.resumen,
    );
  }
}

class NotasCreditoNotifier extends StateNotifier<NotasCreditoState> {
  final FacturacionService _service = FacturacionService();

  NotasCreditoNotifier() : super(NotasCreditoState());

  Future<void> fetchHistorial(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.getNotasCredito(
      token: token,
      filters: state.filters,
    );

    if (result['success']) {
      final List<dynamic> data = result['data']['data'] ?? [];
      final List<NotaCreditoModel> notas = data.map((json) => NotaCreditoModel.fromJson(json)).toList();
      state = state.copyWith(
        isLoading: false,
        historial: notas,
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
}

final notasCreditoProvider = StateNotifierProvider<NotasCreditoNotifier, NotasCreditoState>((ref) {
  return NotasCreditoNotifier();
});
