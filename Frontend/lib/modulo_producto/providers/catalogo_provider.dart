import 'package:flutter_riverpod/legacy.dart';
import '../services/catalogo_service.dart';
import '../models/categoria_model.dart';
import '../models/marca_model.dart';
import '../models/unidad_medida_model.dart';
import '../models/impuesto_model.dart';

class GenericCatalogoState<T> {
  final bool isLoading;
  final String? error;
  final List<T> items;

  GenericCatalogoState({
    this.isLoading = false,
    this.error,
    this.items = const [],
  });

  GenericCatalogoState<T> copyWith({
    bool? isLoading,
    String? error,
    List<T>? items,
  }) {
    return GenericCatalogoState<T>(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
    );
  }
}

class GenericCatalogoNotifier<T>
    extends StateNotifier<GenericCatalogoState<T>> {
  final String endpoint;
  final T Function(Map<String, dynamic>) fromJson;

  GenericCatalogoNotifier(this.endpoint, this.fromJson)
    : super(GenericCatalogoState<T>());

  Future<void> fetchAll(String token) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await CatalogoService(endpoint).getAll(token);
      final list = data
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, items: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create(String token, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await CatalogoService(endpoint).create(token, data);
      await fetchAll(token); // Refetch to update list
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateItem(
    String token,
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await CatalogoService(endpoint).update(token, id, data);
      await fetchAll(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteItem(String token, int id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await CatalogoService(endpoint).delete(token, id);
      await fetchAll(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final categoriasProvider =
    StateNotifierProvider<
      GenericCatalogoNotifier<CategoriaModel>,
      GenericCatalogoState<CategoriaModel>
    >((ref) {
      return GenericCatalogoNotifier<CategoriaModel>(
        'categorias',
        CategoriaModel.fromJson,
      );
    });

final marcasProvider =
    StateNotifierProvider<
      GenericCatalogoNotifier<MarcaModel>,
      GenericCatalogoState<MarcaModel>
    >((ref) {
      return GenericCatalogoNotifier<MarcaModel>('marcas', MarcaModel.fromJson);
    });

final unidadesProvider =
    StateNotifierProvider<
      GenericCatalogoNotifier<UnidadMedidaModel>,
      GenericCatalogoState<UnidadMedidaModel>
    >((ref) {
      return GenericCatalogoNotifier<UnidadMedidaModel>(
        'unidades-medida',
        UnidadMedidaModel.fromJson,
      );
    });

final impuestosProvider =
    StateNotifierProvider<
      GenericCatalogoNotifier<ImpuestoModel>,
      GenericCatalogoState<ImpuestoModel>
    >((ref) {
      return GenericCatalogoNotifier<ImpuestoModel>(
        'impuestos',
        ImpuestoModel.fromJson,
      );
    });
