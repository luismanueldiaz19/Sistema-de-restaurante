import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../providers/auth_provider.dart';
import '../models/cxc.dart';
import '../api/cxc_api.dart';

class CxcState {
  final bool isLoading;
  final List<CuentaPorCobrar> cxcs;
  final String? error;

  CxcState({this.isLoading = false, this.cxcs = const [], this.error});

  CxcState copyWith({
    bool? isLoading,
    List<CuentaPorCobrar>? cxcs,
    String? error,
  }) {
    return CxcState(
      isLoading: isLoading ?? this.isLoading,
      cxcs: cxcs ?? this.cxcs,
      error: error,
    );
  }
}

class CxcNotifier extends StateNotifier<CxcState> {
  final Ref ref;
  final CxcApi api;

  CxcNotifier(this.ref, this.api) : super(CxcState()) {
    loadCxcs();
  }

  Future<void> loadCxcs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception('No autenticado');

      final data = await api.getCxcs(token);
      state = state.copyWith(isLoading: false, cxcs: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> registrarPago(int cxcId, Map<String, dynamic> data) async {
    try {
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception('No autenticado');

      final success = await api.registrarPago(token, cxcId, data);
      if (success) {
        await loadCxcs(); // Recargar después de pago
      }
      return success;
    } catch (e) {
      throw Exception('Error al registrar cobro: $e');
    }
  }
}

final cxcProvider = StateNotifierProvider<CxcNotifier, CxcState>((ref) {
  return CxcNotifier(ref, CxcApi());
});
