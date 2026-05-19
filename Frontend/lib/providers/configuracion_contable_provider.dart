import 'package:flutter_riverpod/legacy.dart';
import 'package:sistema_restaurante/services/configuracion_contable_service.dart';
import 'configuracion_contable_state.dart';

class ConfiguracionContableNotifier extends StateNotifier<ConfiguracionContableState> {
  final ConfiguracionContableService _service = ConfiguracionContableService();

  ConfiguracionContableNotifier() : super(ConfiguracionContableState());

  /// 🔄 Cargar configuraciones contables y catálogo de cuentas seleccionables
  Future<void> loadAllData(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final configs = await _service.getConfiguraciones(token: token);
      final cuentas = await _service.getCatalogoCuentas(token: token, permiteMovimiento: true);
      
      state = state.copyWith(
        isLoading: false,
        configuraciones: configs,
        catalogoCuentas: cuentas,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 💾 Guardar las configuraciones en bloque (Bulk save)
  Future<bool> saveBulkConfigurations(String token, List<Map<String, dynamic>> configsList) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updatedConfigs = await _service.bulkUpdateConfiguraciones(
        token: token,
        configs: configsList,
      );
      state = state.copyWith(
        isSaving: false,
        configuraciones: updatedConfigs,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 🔄 Cargar los asientos contables (Libro Diario)
  Future<void> fetchAsientos(
    String token, {
    String? fechaDesde,
    String? fechaHasta,
    String? buscar,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getAsientosContables(
        token: token,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        buscar: buscar,
      );
      state = state.copyWith(
        isLoading: false,
        asientos: list,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final configuracionContableProvider = StateNotifierProvider<ConfiguracionContableNotifier, ConfiguracionContableState>((ref) {
  return ConfiguracionContableNotifier();
});
