import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/cxp.dart';
import '../services/cxp_api.dart';
import '../../providers/auth_provider.dart';

final cxpApiProvider = Provider((ref) => CxpApi());

class CxpState {
  final bool isLoading;
  final List<CuentaPorPagar> cxps;
  final String? error;

  CxpState({this.isLoading = false, this.cxps = const [], this.error});

  CxpState copyWith({
    bool? isLoading,
    List<CuentaPorPagar>? cxps,
    String? error,
  }) {
    return CxpState(
      isLoading: isLoading ?? this.isLoading,
      cxps: cxps ?? this.cxps,
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await api.getAll(token!);
      final list = data.map((e) => CuentaPorPagar.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, cxps: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> registrarPago(int id, Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await api.registrarPago(token!, id, data);
      await loadCxps();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final cxpProvider = StateNotifierProvider<CxpNotifier, CxpState>((ref) {
  final api = ref.watch(cxpApiProvider);
  final token = ref.watch(authProvider).token;
  return CxpNotifier(api, token);
});
