import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/cliente_api.dart';

class ClienteAdminProvider with ChangeNotifier {
  final ClienteApi _clienteApi = ClienteApi();

  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 🔥 CARGAR CLIENTES
  Future<void> loadClients(String token) async {
    _setLoading(true);

    try {
      _clientes = await _clienteApi.fetchClients(token);
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

      final index = _clientes.indexWhere((c) => c.id == id);
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
  Future<void> deleteClient(String id, String token) async {
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
