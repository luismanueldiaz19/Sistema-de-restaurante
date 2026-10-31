import 'dart:convert';
import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/empleado_model.dart';
import '../models/nomina_model.dart';

class NominaService {
  final ApiService api = ApiService();
  final String baseUrl = "$hostName/api";

  /// Obtener lista de empleados
  Future<List<EmpleadoModel>> getEmpleados(String token) async {
    final url = "$baseUrl/empleados";
    try {
      final response = await api.get(url, token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((e) => EmpleadoModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("NOMINA_SERVICE: Error getEmpleados: $e");
      return [];
    }
  }

  /// Crear una nueva nómina
  Future<bool> createNomina(NominaModel nomina, String token) async {
    final url = "$baseUrl/nominas";
    try {
      final response = await api.post(url, nomina.toJson(), token: token);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("NOMINA_SERVICE: Error createNomina: $e");
      return false;
    }
  }

  /// Obtener historial de nóminas
  Future<List<NominaModel>> getNominas(String token) async {
    final url = "$baseUrl/nominas";
    try {
      final response = await api.get(url, token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((e) => NominaModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("NOMINA_SERVICE: Error getNominas: $e");
      return [];
    }
  }

  /// Obtener todos los empleados (activos e inactivos)
  Future<List<EmpleadoModel>> getAllEmpleados(String token) async {
    final url = "$baseUrl/empleados/all";
    try {
      final response = await api.get(url, token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((e) => EmpleadoModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("NOMINA_SERVICE: Error getAllEmpleados: $e");
      return [];
    }
  }

  /// Crear empleado
  Future<bool> createEmpleado(EmpleadoModel empleado, String token) async {
    final url = "$baseUrl/empleados";
    try {
      final response = await api.post(url, empleado.toJson(), token: token);
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar empleado
  Future<bool> updateEmpleado(EmpleadoModel empleado, String token) async {
    final url = "$baseUrl/empleados/${empleado.id}";
    try {
      final response = await api.put(url, empleado.toJson(), token: token);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Alternar estado
  Future<bool> toggleEmpleadoStatus(int id, String token) async {
    final url = "$baseUrl/empleados/$id/toggle";
    try {
      final response = await api.patch(url, {}, token: token);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar estado de nómina
  Future<bool> updateNominaStatus(int id, String status, String token) async {
    final url = "$baseUrl/nominas/$id/status";
    try {
      final response = await api.patch(url, {'estado': status}, token: token);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
