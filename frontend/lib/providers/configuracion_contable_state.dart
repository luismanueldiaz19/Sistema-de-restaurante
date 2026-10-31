import 'package:sistema_restaurante/model/catalogo_cuenta_model.dart';
import 'package:sistema_restaurante/model/configuracion_contable_model.dart';
import 'package:sistema_restaurante/model/asiento_contable_model.dart';

class ConfiguracionContableState {
  final bool isLoading;
  final List<ConfiguracionContableModel> configuraciones;
  final List<CatalogoCuentaModel> catalogoCuentas;
  final List<CatalogoCuentaModel> catalogoCuentasCompleto;
  final List<AsientoContableModel> asientos;
  final String? errorMessage;
  final bool isSaving;

  ConfiguracionContableState({
    this.isLoading = false,
    this.configuraciones = const [],
    this.catalogoCuentas = const [],
    this.catalogoCuentasCompleto = const [],
    this.asientos = const [],
    this.errorMessage,
    this.isSaving = false,
  });

  ConfiguracionContableState copyWith({
    bool? isLoading,
    List<ConfiguracionContableModel>? configuraciones,
    List<CatalogoCuentaModel>? catalogoCuentas,
    List<CatalogoCuentaModel>? catalogoCuentasCompleto,
    List<AsientoContableModel>? asientos,
    String? errorMessage,
    bool? isSaving,
  }) {
    return ConfiguracionContableState(
      isLoading: isLoading ?? this.isLoading,
      configuraciones: configuraciones ?? this.configuraciones,
      catalogoCuentas: catalogoCuentas ?? this.catalogoCuentas,
      catalogoCuentasCompleto:
          catalogoCuentasCompleto ?? this.catalogoCuentasCompleto,
      asientos: asientos ?? this.asientos,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
