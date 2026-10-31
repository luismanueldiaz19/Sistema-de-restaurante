import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';

class DgiiState {
  final bool isLoading;
  final String error;
  final double balanceItbis;
  final List<dynamic> pagos;

  DgiiState({
    this.isLoading = false,
    this.error = '',
    this.balanceItbis = 0.0,
    this.pagos = const [],
  });

  DgiiState copyWith({
    bool? isLoading,
    String? error,
    double? balanceItbis,
    List<dynamic>? pagos,
  }) {
    return DgiiState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      balanceItbis: balanceItbis ?? this.balanceItbis,
      pagos: pagos ?? this.pagos,
    );
  }
}

class DgiiNotifier extends StateNotifier<DgiiState> {
  final Ref ref;
  DgiiNotifier(this.ref) : super(DgiiState());

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, error: '');
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final api = ApiService();

      final resBalance = await api.get(
        '$hostName/api/dgii/balance',
        token: token,
      );
      final resPagos = await api.get('$hostName/api/dgii/pagos', token: token);

      if (resBalance.statusCode == 200 && resPagos.statusCode == 200) {
        final dataBalance = jsonDecode(resBalance.body);
        final dataPagos = jsonDecode(resPagos.body);

        state = state.copyWith(
          isLoading: false,
          balanceItbis: (dataBalance['balance'] as num?)?.toDouble() ?? 0.0,
          pagos: dataPagos,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al cargar datos DGII',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>> registrarPago({
    required String fechaPago,
    required double monto,
    required String mes,
    required String anio,
    required int cuentaBancoId,
    String? referencia,
  }) async {
    final token = ref.read(authProvider).token;
    if (token == null) return {'success': false, 'message': 'No token'};

    try {
      final api = ApiService();
      final res = await api.post('$hostName/api/dgii/pagar', {
        'fecha_pago': fechaPago,
        'monto_pagado': monto,
        'periodo_mes': mes,
        'periodo_anio': anio,
        'cuenta_origen_id': cuentaBancoId,
        'referencia': referencia,
      }, token: token);

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        await fetchDashboardData(); // Recargar balance y pagos
        return {'success': true, 'message': data['message'] ?? 'Exito'};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> exportar606(String mes, String anio) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    // Al ser un archivo para descargar, lo abriremos en el navegador
    // pasándole el token (o el backend debería manejar la sesión web).
    // Otra opción es descargarlo por HTTP y guardarlo local, pero para simplificar en web
    // generaremos una URL con query token o usaremos http y guardaremos archivo.
    final url = Uri.parse(
      '$hostName/api/dgii/exportar-606?mes=$mes&anio=$anio&token=$token',
    );
    await launchUrl(url);
  }

  Future<void> exportar607(String mes, String anio) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    final url = Uri.parse(
      '$hostName/api/dgii/exportar-607?mes=$mes&anio=$anio&token=$token',
    );
    await launchUrl(url);
  }

  Future<List<dynamic>> fetchPreview(
    String tipo,
    String mes,
    String anio,
  ) async {
    final token = ref.read(authProvider).token;
    if (token == null) throw Exception("No autorizado");

    final api = ApiService();
    final url = '$hostName/api/dgii/preview-$tipo?mes=$mes&anio=$anio';
    final response = await api.get(url, token: token);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar vista previa $tipo');
    }
  }
}

final dgiiProvider = StateNotifierProvider<DgiiNotifier, DgiiState>((ref) {
  return DgiiNotifier(ref);
});
