import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/cliente.dart';
import '../services/cliente_api.dart';
import 'cliente_admin_state.dart';

part 'cliente_admin_provider.g.dart';

@riverpod
class ClienteAdmin extends _$ClienteAdmin {
  final ClienteApi _clienteApi = ClienteApi();
  List<Cliente> _allClientes = [];
  Timer? _debounce;

  @override
  ClienteAdminState build() {
    return ClienteAdminState();
  }

  void searchClientes(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = query.toLowerCase().trim();
      if (q.isEmpty) {
        state = state.copyWith(clientes: _allClientes);
      } else {
        final parts = q.split(' ');
        final filtered = _allClientes.where((c) {
          final clientData = "${c.nombre} ${c.telefono} ${c.rncCedula} ${c.email}".toLowerCase();
          return parts.every((part) => clientData.contains(part));
        }).toList();
        state = state.copyWith(clientes: filtered);
      }
    });
  }

  /// 🔥 CARGAR CLIENTES
  Future<void> loadClients(String token) async {
    state = state.copyWith(isLoading: true);

    try {
      final results = await _clienteApi.fetchClients(token);
      
      if (!ref.mounted) return;

      _allClientes = results;
      state = state.copyWith(
        clientes: _allClientes,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  /// 🔥 CREAR CLIENTE
  Future<bool> createClient(Map<String, dynamic> data, String token) async {
    state = state.copyWith(isLoading: true);

    try {
      final newClient = await _clienteApi.createClient(data, token);
      
      if (!ref.mounted) return false;

      _allClientes = [..._allClientes, newClient];
      state = state.copyWith(
        clientes: _allClientes,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
      return false;
    }
  }

  /// 🔥 ACTUALIZAR CLIENTE
  Future<bool> updateClient(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    state = state.copyWith(isLoading: true);

    try {
      final updatedClient = await _clienteApi.updateClient(id, data, token);
      
      if (!ref.mounted) return false;

      _allClientes = _allClientes.map((c) {
        return c.id == int.parse(id) ? updatedClient : c;
      }).toList();

      state = state.copyWith(
        clientes: _allClientes,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
      return false;
    }
  }

  /// 🔥 ELIMINAR CLIENTE
  Future<bool> deleteClient(int id, String token) async {
    state = state.copyWith(isLoading: true);

    try {
      await _clienteApi.deleteClient(id, token);
      
      if (!ref.mounted) return false;

      _allClientes = _allClientes.where((c) => c.id != id).toList();
      state = state.copyWith(
        clientes: _allClientes,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
