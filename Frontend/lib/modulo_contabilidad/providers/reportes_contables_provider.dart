import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../api/reportes_contables_api.dart';

final reportesApiProvider = Provider((ref) => ReportesContablesApi());

// MAYOR GENERAL
final mayorGeneralProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>((ref, paramsStr) async {
      final api = ref.watch(reportesApiProvider);
      final token = ref.watch(authProvider).token;
      if (token == null) throw Exception("No autenticado");

      final parts = paramsStr.split('|');
      return api.getMayorGeneral(
        token,
        fechaDesde: parts[0],
        fechaHasta: parts[1],
      );
    });

// BALANCE GENERAL
final balanceGeneralProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String?>((ref, fechaHasta) async {
      final api = ref.watch(reportesApiProvider);
      final token = ref.watch(authProvider).token;
      if (token == null) throw Exception("No autenticado");

      return api.getBalanceGeneral(token, fechaHasta: fechaHasta);
    });

// ESTADO DE RESULTADOS
final estadoResultadosProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, paramsStr) async {
      final api = ref.watch(reportesApiProvider);
      final token = ref.watch(authProvider).token;
      if (token == null) throw Exception("No autenticado");

      final parts = paramsStr.split('|');
      final fechaDesde = parts[0];
      final fechaHasta = parts[1];
      final incluirCeros = parts.length > 2 ? parts[2] == '1' : false;

      return api.getEstadoResultados(
        token,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        incluirCeros: incluirCeros,
      );
    });
