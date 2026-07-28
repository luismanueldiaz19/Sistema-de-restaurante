import 'package:flutter_riverpod/legacy.dart';
import '../../model/factura.dart';
import '../services/facturacion_service.dart';

class GestionDocumentosState {
  final bool isLoading;
  final String? error;
  final List<Factura> resultados;

  GestionDocumentosState({
    this.isLoading = false,
    this.error,
    this.resultados = const [],
  });

  GestionDocumentosState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Factura>? resultados,
  }) {
    return GestionDocumentosState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      resultados: resultados ?? this.resultados,
    );
  }
}

class GestionDocumentosNotifier extends StateNotifier<GestionDocumentosState> {
  final FacturacionService _service = FacturacionService();

  GestionDocumentosNotifier() : super(GestionDocumentosState());

  Future<void> buscar(
    String token, {
    String query = '',
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final filters = <String, String>{};

    if (query.trim().isNotEmpty) {
      filters['search'] = query.trim();
    }
    if (fechaDesde != null) {
      filters['fecha_desde'] = fechaDesde;
    }
    if (fechaHasta != null) {
      filters['fecha_hasta'] = fechaHasta;
    }

    final result = await _service.getHistorial(token: token, filters: filters);

    if (result['success']) {
      final List<dynamic> data = result['data']['data'] ?? [];
      final List<Factura> facturas = data
          .map((json) => Factura.fromJson(json))
          .toList();
      state = state.copyWith(isLoading: false, resultados: facturas);
    } else {
      state = state.copyWith(isLoading: false, error: result['message']);
    }
  }

  void clear() {
    state = GestionDocumentosState();
  }
}

final gestionDocumentosProvider =
    StateNotifierProvider<GestionDocumentosNotifier, GestionDocumentosState>((
      ref,
    ) {
      return GestionDocumentosNotifier();
    });
