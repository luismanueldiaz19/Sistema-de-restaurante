import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/auth_provider.dart';
import '../models/empleado_model.dart';
import '../models/nomina_model.dart';
import '../services/nomina_service.dart';
import 'nomina_state.dart';
part 'nomina_provider.g.dart';

@Riverpod(keepAlive: true)
class Nomina extends _$Nomina {
  final NominaService _service = NominaService();

  @override
  NominaState build() {
    return NominaState();
  }

  /// Cargar empleados para la nómina
  Future<void> fetchEmpleados() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final empleados = await _service.getEmpleados(token);
      state = state.copyWith(empleados: empleados, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Cargar historial de nóminas
  Future<void> fetchHistorial() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final historial = await _service.getNominas(token);
      state = state.copyWith(historialNominas: historial, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 🔐 Verificar si el usuario tiene acceso al módulo de nómina
  bool canAccess() {
    final authState = ref.read(authProvider);
    final roles = authState.roles.map((e) => e.toLowerCase()).toList();

    return roles.contains('admin') ||
        roles.contains('contador') ||
        roles.contains('auxiliar contable');
  }

  /// Guardar una nueva nómina
  Future<bool> createNomina(NominaModel nomina) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.createNomina(nomina, token);
      if (success) {
        await fetchHistorial(); // Recargar historial
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Cargar todos los empleados (activos e inactivos)
  Future<void> fetchAllEmpleados() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final empleados = await _service.getAllEmpleados(token);
      state = state.copyWith(empleados: empleados, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Crear o actualizar empleado
  Future<bool> saveEmpleado(EmpleadoModel empleado) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      bool success;
      if (empleado.id == null) {
        success = await _service.createEmpleado(empleado, token);
      } else {
        success = await _service.updateEmpleado(empleado, token);
      }

      if (success) {
        await fetchAllEmpleados();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Alternar estado del empleado
  Future<bool> toggleEmpleadoStatus(int id) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    try {
      final success = await _service.toggleEmpleadoStatus(id, token);
      if (success) {
        await fetchAllEmpleados();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar estado de la nómina
  Future<bool> updateNominaStatus(int id, String status) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updateNominaStatus(id, status, token);
      if (success) {
        await fetchHistorial();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
