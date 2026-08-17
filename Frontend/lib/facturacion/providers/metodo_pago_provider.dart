import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/metodo_pago.dart';
import '../services/metodo_pago_service.dart';

class MetodoPagoNotifier extends ChangeNotifier {
  final MetodoPagoService _service = MetodoPagoService();

  List<MetodoPago> _metodos = [];
  bool _isLoading = false;
  String _error = '';

  List<MetodoPago> get metodos => _metodos;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchMetodosActivos() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _metodos = await _service.getMetodosPagoActivos();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodos() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _metodos = await _service.getTodosMetodosPago();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> crearMetodo(Map<String, dynamic> data) async {
    try {
      final nuevo = await _service.createMetodoPago(data);
      _metodos.add(nuevo);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> actualizarMetodo(int id, Map<String, dynamic> data) async {
    try {
      final actualizado = await _service.updateMetodoPago(id, data);
      final index = _metodos.indexWhere((m) => m.id == id);
      if (index != -1) {
        _metodos[index] = actualizado;
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> eliminarMetodo(int id) async {
    try {
      await _service.deleteMetodoPago(id);
      _metodos.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}

final metodoPagoProvider = ChangeNotifierProvider((ref) => MetodoPagoNotifier());
