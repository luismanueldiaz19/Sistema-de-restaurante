import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/cliente_api.dart';

class ClienteAdminProvider with ChangeNotifier {
  final ClienteApi _clienteApi = ClienteApi();

  List<Cliente> _clientes = [];

  List<Cliente> _allClientes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Timer? _debounce;
  String _searchQuery = '';

  void searchClientes(String query) {
    _searchQuery = query;

    // cancelar debounce anterior
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // nuevo debounce
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _clientes = _allClientes;
    } else {
      _clientes = _allClientes.where((c) {
        return c.nombre!.toLowerCase().contains(query.toLowerCase()) ||
            (c.telefono ?? '').contains(query);
      }).toList();
    }

    notifyListeners();
  }

  /// 🔥 CARGAR CLIENTES
  Future<void> loadClients(String token) async {
    _setLoading(true);

    try {
      _allClientes = await _clienteApi.fetchClients(token);
      _clientes = _allClientes;
      _errorMessage = null;
      print("CLIENTES EN PROVIDER: ${_clientes.length}"); // 👈
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
    print("CLIENTES EN PROVIDER: ${_clientes.length}"); // 👈
    _setLoading(false); // 🔥 aquí sí refresca UI
  }

  /// 🔥 OBTENER CLIENTE POR ID
  Future<Cliente?> getClientById(String id, String token) async {
    try {
      return await _clienteApi.getClientById(id, token);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 🔥 CREAR CLIENTE
  Future<void> createClient(Map<String, dynamic> data, String token) async {
    _setLoading(true);

    try {
      final newClient = await _clienteApi.createClient(data, token);
      _clientes.add(newClient);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _setLoading(false);
  }

  /// 🔥 ACTUALIZAR CLIENTE
  Future<void> updateClient(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    _setLoading(true);

    try {
      final updatedClient = await _clienteApi.updateClient(id, data, token);

      final index = _clientes.indexWhere((c) => c.id == int.parse(id));
      if (index != -1) {
        _clientes[index] = updatedClient;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _setLoading(false);
  }

  /// 🔥 ELIMINAR CLIENTE
  Future<void> deleteClient(int id, String token) async {
    _setLoading(true);

    try {
      await _clienteApi.deleteClient(id, token);

      _clientes.removeWhere((c) => c.id == id);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _setLoading(false);
  }

  /// 🔥 REFRESH
  Future<void> refresh(String token) async {
    await loadClients(token);
  }

  /// 🔥 LOADING CONTROL
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 🔥 LIMPIAR ERROR
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
