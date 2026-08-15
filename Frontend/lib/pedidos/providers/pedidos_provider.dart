import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/pedido.dart';
import '../services/pedido_service.dart';

class PedidosProvider with ChangeNotifier {
  final PedidoService _pedidoService = PedidoService();

  List<Pedido> _pedidos = [];
  bool _isLoading = false;
  String _error = '';
  DateTime _currentDate = DateTime.now();
  Timer? _timer;

  List<Pedido> get pedidos => _pedidos;
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime get currentDate => _currentDate;

  void initPolling() {
    fetchPedidos();
    // Poll every 15 seconds
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchPedidos(silent: true);
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void changeDate(DateTime date) {
    _currentDate = date;
    fetchPedidos();
  }

  Future<void> fetchPedidos({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final formattedDate =
          "${_currentDate.year}-${_currentDate.month.toString().padLeft(2, '0')}-${_currentDate.day.toString().padLeft(2, '0')}";
      _pedidos = await _pedidoService.getPedidos(formattedDate);
      _error = '';
    } catch (e) {
      if (!silent) _error = e.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> updatePedidoStatus(int id, String newStatus) async {
    try {
      final updatedPedido = await _pedidoService.updateStatus(id, newStatus);
      final index = _pedidos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _pedidos[index] = updatedPedido;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('No se pudo actualizar: $e');
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final pedidosProvider = ChangeNotifierProvider<PedidosProvider>((ref) {
  return PedidosProvider();
});
