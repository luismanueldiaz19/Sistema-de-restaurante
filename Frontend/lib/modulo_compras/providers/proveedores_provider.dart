import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/proveedor.dart';
import '../services/proveedor_api.dart';
import '../../providers/auth_provider.dart';

final proveedorApiProvider = Provider((ref) => ProveedorApi());

class ProveedoresState {
  final bool isLoading;
  final List<Proveedor> proveedores;
  final String? error;

  ProveedoresState({
    this.isLoading = false,
    this.proveedores = const [],
    this.error,
  });

  ProveedoresState copyWith({
    bool? isLoading,
    List<Proveedor>? proveedores,
    String? error,
  }) {
    return ProveedoresState(
      isLoading: isLoading ?? this.isLoading,
      proveedores: proveedores ?? this.proveedores,
      error: error ?? this.error,
    );
  }
}

class ProveedoresNotifier extends StateNotifier<ProveedoresState> {
  final ProveedorApi api;
  final String? token;

  ProveedoresNotifier(this.api, this.token) : super(ProveedoresState()) {
    if (token != null) {
      loadProveedores();
    }
  }

  Future<void> loadProveedores() async {
    if (token == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await api.getAll(token!);
      final list = data.map((e) => Proveedor.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, proveedores: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createProveedor(Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await api.create(token!, data);
      await loadProveedores();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateProveedor(int id, Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await api.update(token!, id, data);
      await loadProveedores();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProveedor(int id) async {
    if (token == null) return false;
    try {
      await api.delete(token!, id);
      await loadProveedores();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final proveedoresProvider =
    StateNotifierProvider<ProveedoresNotifier, ProveedoresState>((ref) {
      final api = ref.watch(proveedorApiProvider);
      final token = ref.watch(authProvider).token;
      return ProveedoresNotifier(api, token);
    });
