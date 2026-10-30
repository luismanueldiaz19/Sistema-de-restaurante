import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../providers/auth_provider.dart';
import '../models/ecf_models.dart';
import '../services/ecf_api_service.dart';

class EcfState {
  final bool isLoading;
  final bool isActionLoading;
  final String error;
  final EcfConfigModel config;
  final EcfCertificadoMeta certificado;
  final Map<String, int> estadisticas;
  final List<EcfDocumentoItem> documentos;
  final int currentPage;
  final int lastPage;
  final String filtroEstado;
  final String filtroTipoEcf;
  final String search;

  const EcfState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.error = '',
    this.config = const EcfConfigModel(),
    this.certificado = const EcfCertificadoMeta(),
    this.estadisticas = const {
      'total': 0,
      'aceptados': 0,
      'en_proceso': 0,
      'pendientes': 0,
      'rechazados': 0,
    },
    this.documentos = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.filtroEstado = '',
    this.filtroTipoEcf = '',
    this.search = '',
  });

  EcfState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    String? error,
    EcfConfigModel? config,
    EcfCertificadoMeta? certificado,
    Map<String, int>? estadisticas,
    List<EcfDocumentoItem>? documentos,
    int? currentPage,
    int? lastPage,
    String? filtroEstado,
    String? filtroTipoEcf,
    String? search,
  }) {
    return EcfState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: error ?? this.error,
      config: config ?? this.config,
      certificado: certificado ?? this.certificado,
      estadisticas: estadisticas ?? this.estadisticas,
      documentos: documentos ?? this.documentos,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      filtroTipoEcf: filtroTipoEcf ?? this.filtroTipoEcf,
      search: search ?? this.search,
    );
  }
}

class EcfNotifier extends StateNotifier<EcfState> {
  final Ref ref;
  final EcfApiService _service = EcfApiService();

  EcfNotifier(this.ref) : super(const EcfState());

  String? get _token => ref.read(authProvider).token;

  Future<void> cargarTodo() async {
    final token = _token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, error: '');
    try {
      final results = await Future.wait([
        _service.getEstadoSistema(token),
        _service.getDocumentos(
          token,
          page: state.currentPage,
          estado: state.filtroEstado,
          tipoEcf: state.filtroTipoEcf,
          search: state.search,
        ),
      ]);

      final estadoRes = results[0];
      final docsRes = results[1];

      EcfConfigModel cfg = state.config;
      EcfCertificadoMeta cert = state.certificado;
      Map<String, int> stats = state.estadisticas;

      if (estadoRes['success'] == true) {
        if (estadoRes['configuracion'] is Map<String, dynamic>) {
          cfg = EcfConfigModel.fromJson(estadoRes['configuracion']);
        }
        if (estadoRes['certificado'] is Map<String, dynamic>) {
          cert = EcfCertificadoMeta.fromJson(estadoRes['certificado']);
        }
        if (estadoRes['estadisticas'] is Map) {
          final raw = estadoRes['estadisticas'] as Map;
          stats = {
            'total': (raw['total'] as num?)?.toInt() ?? 0,
            'aceptados': (raw['aceptados'] as num?)?.toInt() ?? 0,
            'en_proceso': (raw['en_proceso'] as num?)?.toInt() ?? 0,
            'pendientes': (raw['pendientes'] as num?)?.toInt() ?? 0,
            'rechazados': (raw['rechazados'] as num?)?.toInt() ?? 0,
          };
        }
      }

      List<EcfDocumentoItem> items = state.documentos;
      int curPage = 1;
      int lastPage = 1;
      if (docsRes['success'] == true && docsRes['data'] is Map) {
        final paginated = docsRes['data'] as Map;
        curPage = (paginated['current_page'] as num?)?.toInt() ?? 1;
        lastPage = (paginated['last_page'] as num?)?.toInt() ?? 1;
        final rawList = (paginated['data'] as List?) ?? [];
        items = rawList
            .whereType<Map<String, dynamic>>()
            .map(EcfDocumentoItem.fromJson)
            .toList();
      }

      state = state.copyWith(
        isLoading: false,
        config: cfg,
        certificado: cert,
        estadisticas: stats,
        documentos: items,
        currentPage: curPage,
        lastPage: lastPage,
        error: estadoRes['success'] == true
            ? ''
            : (estadoRes['message'] ?? '').toString(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> aplicarFiltros({
    String? estado,
    String? tipoEcf,
    String? search,
    int page = 1,
  }) async {
    state = state.copyWith(
      filtroEstado: estado ?? state.filtroEstado,
      filtroTipoEcf: tipoEcf ?? state.filtroTipoEcf,
      search: search ?? state.search,
      currentPage: page,
    );
    await cargarTodo();
  }

  Future<Map<String, dynamic>> guardarConfiguracion(
    Map<String, dynamic> payload,
  ) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    state = state.copyWith(isActionLoading: true);
    try {
      final res = await _service.actualizarConfiguracion(token, payload);
      if (res['success'] == true) await cargarTodo();
      return res;
    } finally {
      state = state.copyWith(isActionLoading: false);
    }
  }

  Future<Map<String, dynamic>> generarCertificadoPrueba({
    String password = '1234',
  }) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    state = state.copyWith(isActionLoading: true);
    try {
      final res = await _service.generarCertificadoPrueba(
        token,
        password: password,
      );
      if (res['success'] == true) await cargarTodo();
      return res;
    } finally {
      state = state.copyWith(isActionLoading: false);
    }
  }

  Future<Map<String, dynamic>> subirCertificadoP12({
    required List<int> fileBytes,
    required String fileName,
    required String password,
  }) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    state = state.copyWith(isActionLoading: true);
    try {
      final res = await _service.subirCertificadoP12(
        token,
        fileBytes: fileBytes,
        fileName: fileName,
        password: password,
      );
      if (res['success'] == true) await cargarTodo();
      return res;
    } finally {
      state = state.copyWith(isActionLoading: false);
    }
  }

  Future<Map<String, dynamic>> probarConexion() async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    state = state.copyWith(isActionLoading: true);
    try {
      return await _service.probarConexion(token);
    } finally {
      state = state.copyWith(isActionLoading: false);
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleDocumento(int id) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    return _service.getDocumentoDetalle(token, id);
  }

  Future<Map<String, dynamic>> reenviarDocumento(int id) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    state = state.copyWith(isActionLoading: true);
    try {
      final res = await _service.reenviarDocumento(token, id);
      if (res['success'] == true) await cargarTodo();
      return res;
    } finally {
      state = state.copyWith(isActionLoading: false);
    }
  }

  Future<Map<String, dynamic>> consultarTrackId(int id) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};
    state = state.copyWith(isActionLoading: true);
    try {
      final res = await _service.consultarEstadoDocumento(token, id);
      if (res['success'] == true) await cargarTodo();
      return res;
    } finally {
      state = state.copyWith(isActionLoading: false);
    }
  }
}

final ecfProvider = StateNotifierProvider<EcfNotifier, EcfState>((ref) {
  return EcfNotifier(ref);
});
