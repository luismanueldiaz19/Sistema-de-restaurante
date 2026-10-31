import '../models/empleado_model.dart';
import '../models/nomina_model.dart';

class NominaState {
  final bool isLoading;
  final List<EmpleadoModel> empleados;
  final List<NominaModel> historialNominas;
  final NominaModel? nominaActual;
  final String? error;

  NominaState({
    this.isLoading = false,
    this.empleados = const [],
    this.historialNominas = const [],
    this.nominaActual,
    this.error,
  });

  NominaState copyWith({
    bool? isLoading,
    List<EmpleadoModel>? empleados,
    List<NominaModel>? historialNominas,
    NominaModel? nominaActual,
    String? error,
  }) {
    return NominaState(
      isLoading: isLoading ?? this.isLoading,
      empleados: empleados ?? this.empleados,
      historialNominas: historialNominas ?? this.historialNominas,
      nominaActual: nominaActual ?? this.nominaActual,
      error: error ?? this.error,
    );
  }
}
