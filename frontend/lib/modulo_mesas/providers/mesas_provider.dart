import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/mesa_model.dart';
import '../services/mesa_service.dart';

class MesasProvider with ChangeNotifier {
  final MesaService _service = MesaService();

  List<MesaModel> _mesas = [];
  List<String> _areas = ['Todas', 'Principal'];
  String _selectedArea = 'Todas';
  bool _isLoading = false;
  String _error = '';
  Timer? _timer;

  List<MesaModel> get mesas => _mesas;
  List<String> get areas => _areas;
  String get selectedArea => _selectedArea;
  bool get isLoading => _isLoading;
  String get error => _error;

  int get totalMesas => _mesas.length;
  int get mesasLibres => _mesas.where((m) => m.isLibre).length;
  int get mesasOcupadas => _mesas.where((m) => m.isOcupada).length;
  int get mesasPorCobrar => _mesas.where((m) => m.isPorCobrar).length;

  void initPolling() {
    fetchMesas();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchMesas(silent: true);
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void setArea(String area) {
    _selectedArea = area;
    fetchMesas();
  }

  Future<void> fetchMesas({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final result = await _service.getMesas(
        area: _selectedArea == 'Todas' ? null : _selectedArea,
      );
      _mesas = result['mesas'];
      _ordenarMesas();

      final List<String> fetchedAreas = ['Todas', ...result['areas']];
      _areas = fetchedAreas.toSet().toList();
      _error = '';
    } catch (e) {
      if (!silent) _error = e.toString();
    } finally {
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  void _ordenarMesas() {
    _mesas.sort((a, b) {
      final reg = RegExp(r'\d+');
      final matchA = reg.firstMatch(a.nombre);
      final matchB = reg.firstMatch(b.nombre);

      final numA = matchA != null ? int.tryParse(matchA.group(0)!) : null;
      final numB = matchB != null ? int.tryParse(matchB.group(0)!) : null;

      if (numA != null && numB != null && numA != numB) {
        return numA.compareTo(numB);
      }

      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
  }

  Future<MesaModel> crearMesa({
    required String nombre,
    required String area,
    required int capacidad,
  }) async {
    try {
      final nuevaMesa = await _service.crearMesa({
        'nombre': nombre,
        'area': area,
        'capacidad': capacidad,
      });
      _mesas.add(nuevaMesa);
      _ordenarMesas();
      if (!_areas.contains(area)) {
        _areas.add(area);
      }
      notifyListeners();
      return nuevaMesa;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<MesaModel> actualizarMesa(int id, Map<String, dynamic> payload) async {
    try {
      final actualizada = await _service.actualizarMesa(id, payload);
      final index = _mesas.indexWhere((m) => m.id == id);
      if (index != -1) {
        _mesas[index] = actualizada;
        _ordenarMesas();
        notifyListeners();
      }
      return actualizada;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> eliminarMesa(int id) async {
    try {
      await _service.eliminarMesa(id);
      _mesas.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<MesaModel> abrirMesa(int id, Map<String, dynamic> payload) async {
    final index = _mesas.indexWhere((m) => m.id == id);
    MesaModel? oldMesa;
    if (index != -1) {
      oldMesa = _mesas[index];
      // Optimistic state
      _mesas[index] = oldMesa.copyWith(estado: 'Ocupada');
      notifyListeners();
    }

    try {
      final mesaAbierta = await _service.abrirMesa(id, payload);
      final curIndex = _mesas.indexWhere((m) => m.id == id);
      if (curIndex != -1) {
        _mesas[curIndex] = mesaAbierta;
        notifyListeners();
      }
      return mesaAbierta;
    } catch (e) {
      if (index != -1 && oldMesa != null) {
        _mesas[index] = oldMesa;
        notifyListeners();
      }
      throw Exception(e.toString());
    }
  }

  Future<MesaModel> agregarItems(int id, Map<String, dynamic> payload) async {
    try {
      final mesaActualizada = await _service.agregarItems(id, payload);
      final index = _mesas.indexWhere((m) => m.id == id);
      if (index != -1) {
        _mesas[index] = mesaActualizada;
        notifyListeners();
      }
      return mesaActualizada;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<MesaModel> solicitarCuenta(int id) async {
    final index = _mesas.indexWhere((m) => m.id == id);
    MesaModel? oldMesa;
    if (index != -1) {
      oldMesa = _mesas[index];
      _mesas[index] = oldMesa.copyWith(estado: 'PorCobrar');
      notifyListeners();
    }

    try {
      final actualizada = await _service.solicitarCuenta(id);
      final curIndex = _mesas.indexWhere((m) => m.id == id);
      if (curIndex != -1) {
        _mesas[curIndex] = actualizada;
        notifyListeners();
      }
      return actualizada;
    } catch (e) {
      if (index != -1 && oldMesa != null) {
        _mesas[index] = oldMesa;
        notifyListeners();
      }
      throw Exception(e.toString());
    }
  }

  Future<MesaModel> liberarMesa(int id, {bool porFactura = false}) async {
    final index = _mesas.indexWhere((m) => m.id == id);
    MesaModel? oldMesa;
    if (index != -1) {
      oldMesa = _mesas[index];
      _mesas[index] = oldMesa.copyWith(estado: 'Libre', clearOrdenActiva: true);
      notifyListeners();
    }

    try {
      final liberada = await _service.liberarMesa(id, porFactura: porFactura);
      final curIndex = _mesas.indexWhere((m) => m.id == id);
      if (curIndex != -1) {
        _mesas[curIndex] = liberada;
        notifyListeners();
      }
      return liberada;
    } catch (e) {
      if (index != -1 && oldMesa != null) {
        _mesas[index] = oldMesa;
        notifyListeners();
      }
      throw Exception(e.toString());
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final mesasProvider = ChangeNotifierProvider<MesasProvider>((ref) {
  return MesasProvider();
});
