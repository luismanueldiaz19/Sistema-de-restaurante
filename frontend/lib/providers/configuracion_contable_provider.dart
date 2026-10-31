import 'package:flutter_riverpod/legacy.dart';
import 'package:sistema_restaurante/services/configuracion_contable_service.dart';
import '../model/catalogo_cuenta_model.dart';
import 'configuracion_contable_state.dart';

class ConfiguracionContableNotifier
    extends StateNotifier<ConfiguracionContableState> {
  final ConfiguracionContableService _service = ConfiguracionContableService();

  ConfiguracionContableNotifier() : super(ConfiguracionContableState());

  /// 🔄 Cargar configuraciones contables y catálogo de cuentas seleccionables
  Future<void> loadAllData(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final configs = await _service.getConfiguraciones(token: token);
      final cuentas = await _service.getCatalogoCuentas(
        token: token,
        permiteMovimiento: true,
      );
      final cuentasCompleto = await _service.getCatalogoCuentas(token: token);

      state = state.copyWith(
        isLoading: false,
        configuraciones: configs,
        catalogoCuentas: cuentas,
        catalogoCuentasCompleto: cuentasCompleto,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 💾 Guardar las configuraciones en bloque (Bulk save)
  Future<bool> saveBulkConfigurations(
    String token,
    List<Map<String, dynamic>> configsList,
  ) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updatedConfigs = await _service.bulkUpdateConfiguraciones(
        token: token,
        configs: configsList,
      );
      state = state.copyWith(isSaving: false, configuraciones: updatedConfigs);
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
      state = state.copyWith(isLoading: false, asientos: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 📥 Crear nueva cuenta en el catálogo
  Future<void> crearCuenta(String token, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final nuevaCuenta = await _service.createCatalogoCuenta(
        token: token,
        data: data,
      );

      final updatedList = [...state.catalogoCuentasCompleto, nuevaCuenta];
      // Si permite movimiento, también la añadimos a la lista corta
      final updatedListTransaccional = [...state.catalogoCuentas];
      if (nuevaCuenta.permiteMovimiento) {
        updatedListTransaccional.add(nuevaCuenta);
      }

      state = state.copyWith(
        isLoading: false,
        catalogoCuentasCompleto: updatedList,
        catalogoCuentas: updatedListTransaccional,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// ✏️ Actualizar cuenta en el catálogo
  Future<void> actualizarCuenta(
    String token,
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final cuentaActualizada = await _service.updateCatalogoCuenta(
        token: token,
        id: id,
        data: data,
      );

      final updatedList = state.catalogoCuentasCompleto
          .map((c) => c.id == id ? cuentaActualizada : c)
          .toList();

      // Actualizar también en la lista transaccional si estaba ahí, o añadirla si ahora permite movimiento
      List<CatalogoCuentaModel> updatedListTransaccional = [
        ...state.catalogoCuentas,
      ];
      final index = updatedListTransaccional.indexWhere((c) => c.id == id);
      if (cuentaActualizada.permiteMovimiento) {
        if (index != -1) {
          updatedListTransaccional[index] = cuentaActualizada;
        } else {
          updatedListTransaccional.add(cuentaActualizada);
        }
      } else {
        if (index != -1) {
          updatedListTransaccional.removeAt(index);
        }
      }

      state = state.copyWith(
        isLoading: false,
        catalogoCuentasCompleto: updatedList,
        catalogoCuentas: updatedListTransaccional,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// 🗑️ Eliminar cuenta del catálogo
  Future<void> eliminarCuenta(String token, int id) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _service.deleteCatalogoCuenta(token: token, id: id);

      final updatedList = state.catalogoCuentasCompleto
          .where((c) => c.id != id)
          .toList();
      final updatedListTransaccional = state.catalogoCuentas
          .where((c) => c.id != id)
          .toList();

      state = state.copyWith(
        isLoading: false,
        catalogoCuentasCompleto: updatedList,
        catalogoCuentas: updatedListTransaccional,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final configuracionContableProvider =
    StateNotifierProvider<
      ConfiguracionContableNotifier,
      ConfiguracionContableState
    >((ref) {
      return ConfiguracionContableNotifier();
    });
