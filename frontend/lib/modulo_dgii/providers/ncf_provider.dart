import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../providers/auth_provider.dart';
import '../models/ncf_secuencia_model.dart';
import '../services/ncf_api_service.dart';

class NcfState {
  final bool isLoading;
  final bool isSaving;
  final String error;
  final List<NcfSecuenciaModel> secuencias;
  final String search;
  final String filtroEstado; // '', 'activas', 'inactivas'

  const NcfState({
    this.isLoading = false,
    this.isSaving = false,
    this.error = '',
    this.secuencias = const [],
    this.search = '',
    this.filtroEstado = '',
  });

  List<NcfSecuenciaModel> get filtradas {
    return secuencias.where((s) {
      if (filtroEstado == 'activas' && !s.activo) return false;
      if (filtroEstado == 'inactivas' && s.activo) return false;
      if (search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        final match =
            s.codigo.toLowerCase().contains(q) ||
            s.nombre.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  NcfState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    List<NcfSecuenciaModel>? secuencias,
    String? search,
    String? filtroEstado,
  }) {
    return NcfState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
      secuencias: secuencias ?? this.secuencias,
      search: search ?? this.search,
      filtroEstado: filtroEstado ?? this.filtroEstado,
    );
  }
}

class NcfNotifier extends StateNotifier<NcfState> {
  final Ref ref;
  final NcfApiService _service = NcfApiService();

  NcfNotifier(this.ref) : super(const NcfState());

  String? get _token => ref.read(authProvider).token;

  Future<void> cargarSecuencias() async {
    final token = _token;
    if (token == null) return;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final res = await _service.listarTodas(token);
      if (res['success'] == true) {
        final list = ((res['data'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(NcfSecuenciaModel.fromJson)
            .toList();
        state = state.copyWith(isLoading: false, secuencias: list);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: (res['message'] ?? '').toString(),
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFiltros({String? search, String? estado}) {
    state = state.copyWith(
      search: search ?? state.search,
      filtroEstado: estado ?? state.filtroEstado,
    );
  }

  Future<Map<String, dynamic>> guardarSecuencia({
    int? id,
    required Map<String, dynamic> payload,
  }) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    state = state.copyWith(isSaving: true);
    try {
      final res = id == null
          ? await _service.crear(token, payload)
          : await _service.actualizar(token, id, payload);
      if (res['success'] == true) await cargarSecuencias();
      return res;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<Map<String, dynamic>> toggleActivo(int id) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    final res = await _service.toggleActivo(token, id);
    if (res['success'] == true) await cargarSecuencias();
    return res;
  }
}

final ncfProvider = StateNotifierProvider<NcfNotifier, NcfState>((ref) {
  return NcfNotifier(ref);
});

