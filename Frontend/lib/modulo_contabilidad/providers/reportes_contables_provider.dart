import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../api/reportes_contables_api.dart';

final reportesApiProvider = Provider((ref) => ReportesContablesApi());

// MAYOR GENERAL
final mayorGeneralProvider = FutureProvider.family<List<dynamic>, String>((ref, paramsStr) async {
  final api = ref.watch(reportesApiProvider);
  final token = ref.watch(authProvider).token;
  if (token == null) throw Exception("No autenticado");
  
  final parts = paramsStr.split('|');
  return api.getMayorGeneral(token, fechaDesde: parts[0], fechaHasta: parts[1]);
});

// BALANCE GENERAL
final balanceGeneralProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, fechaHasta) async {
  final api = ref.watch(reportesApiProvider);
  final token = ref.watch(authProvider).token;
  if (token == null) throw Exception("No autenticado");
  
  return api.getBalanceGeneral(token, fechaHasta: fechaHasta);
});

// ESTADO DE RESULTADOS
final estadoResultadosProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, paramsStr) async {
  final api = ref.watch(reportesApiProvider);
  final token = ref.watch(authProvider).token;
  if (token == null) throw Exception("No autenticado");
  
  final parts = paramsStr.split('|');
  return api.getEstadoResultados(token, fechaDesde: parts[0], fechaHasta: parts[1]);
});
