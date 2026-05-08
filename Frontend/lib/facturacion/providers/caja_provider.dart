import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/caja_model.dart';
import '../services/caja_service.dart';
import '../../providers/auth_provider.dart';

class CajaState {
  final CajaSesion? sesionActiva;
  final bool isLoading;
  final String? error;

  CajaState({this.sesionActiva, this.isLoading = false, this.error});

  CajaState copyWith({
    CajaSesion? sesionActiva,
    bool? isLoading,
    String? error,
  }) {
    return CajaState(
      sesionActiva: sesionActiva ?? this.sesionActiva,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CajaNotifier extends StateNotifier<CajaState> {
  final CajaService _service = CajaService();
  final Ref ref;

  CajaNotifier(this.ref) : super(CajaState()) {
    checkEstado();
  }

  Future<void> checkEstado() async {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final sesion = await _service.getEstadoActual(auth.token!);
      state = state.copyWith(sesionActiva: sesion, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> abrirCaja(int cajaId, int turnoId, double monto) async {
    final auth = ref.read(authProvider);
    state = state.copyWith(isLoading: true);

    try {
      final res = await _service.abrirCaja(
        token: auth.token!,
        cajaId: cajaId,
        turnoId: turnoId,
        montoInicial: monto,
      );

      if (res['data'] != null) {
        state = state.copyWith(
          sesionActiva: CajaSesion.fromJson(res['data']),
          isLoading: false,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> cerrarCaja(double montoFisico, {String? comentario}) async {
    final auth = ref.read(authProvider);
    state = state.copyWith(isLoading: true);

    try {
      final res = await _service.cerrarCaja(
        token: auth.token!,
        montoFisico: montoFisico,
        comentario: comentario,
      );

      if (res['data'] != null) {
        state = state.copyWith(sesionActiva: null, isLoading: false);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }
}

final cajaProvider = StateNotifierProvider<CajaNotifier, CajaState>((ref) {
  return CajaNotifier(ref);
});
