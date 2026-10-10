import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/cxp.dart';
import '../models/pago_compra.dart';
import '../services/cxp_api.dart';
import '../../providers/auth_provider.dart';

final cxpApiProvider = Provider((ref) => CxpApi());

class CxpState {
  final bool isLoading;
  final List<CuentaPorPagar> cxps;
  final List<PagoCompra> historialPagos;
  final String? error;

  CxpState({
    this.isLoading = false,
    this.cxps = const [],
    this.historialPagos = const [],
    this.error,
  });

  CxpState copyWith({
    bool? isLoading,
    List<CuentaPorPagar>? cxps,
    List<PagoCompra>? historialPagos,
    String? error,
  }) {
    return CxpState(
      isLoading: isLoading ?? this.isLoading,
      cxps: cxps ?? this.cxps,
      historialPagos: historialPagos ?? this.historialPagos,
      error: error ?? this.error,
    );
  }
}

class CxpNotifier extends StateNotifier<CxpState> {
  final CxpApi api;
  final String? token;

  CxpNotifier(this.api, this.token) : super(CxpState()) {
    if (token != null) {
      loadCxps();
    }
  }

  Future<void> loadCxps() async {
    if (token == null) return;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final data = await api.getAll(token!);
      final list = data.map((e) => CuentaPorPagar.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, cxps: list, error: '');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchHistorialPagos() async {
    state = state.copyWith(isLoading: true, error: '');
    if (token == null) return;
    try {
      final data = await api.getHistorialPagos(token!);
      final listData = data['data'] as List<dynamic>? ?? [];
      final pagos = listData.map((e) => PagoCompra.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, historialPagos: pagos, error: '');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> registrarPago(int id, Map<String, dynamic> data) async {
    if (token == null) return 'No auth token';
    try {
      await api.registrarPago(token!, id, data);
      await loadCxps();
      return null;
    } catch (e) {
      // Retorna el mensaje de error para mostrarlo en el Toast
      return e.toString();
    }
  }

  Future<List<PagoCompra>> getPagosPorCompra(int compraId) async {
    if (token == null) return [];
    try {
      final data = await api.getPagosPorCompra(token!, compraId);
      return data.map((e) => PagoCompra.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

final cxpProvider = StateNotifierProvider<CxpNotifier, CxpState>((ref) {
  final api = ref.watch(cxpApiProvider);
  final token = ref.watch(authProvider).token;
  return CxpNotifier(api, token);
});
