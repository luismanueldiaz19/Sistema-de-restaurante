import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../models/ingrediente.dart';

final ingredienteProvider =
    StateNotifierProvider<IngredienteNotifier, List<Ingrediente>>((ref) {
      return IngredienteNotifier();
    });

class IngredienteNotifier extends StateNotifier<List<Ingrediente>> {
  IngredienteNotifier() : super([]);

  bool isLoading = false;

  Future<void> fetchIngredientes(String token) async {
    try {
      isLoading = true;
      final response = await http.get(
        Uri.parse('$hostName/ingredientes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        state = data.map((x) => Ingrediente.fromJson(x)).toList();
      }
    } catch (e) {
      print("Error fetching ingredientes: $e");
    } finally {
      isLoading = false;
    }
  }

  Future<bool> createIngrediente(
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$hostName/ingredientes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        fetchIngredientes(token);
        return true;
      }
      return false;
    } catch (e) {
      print("Error creating ingrediente: $e");
      return false;
    }
  }

  Future<bool> updateIngrediente(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$hostName/ingredientes/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        fetchIngredientes(token);
        return true;
      }
      return false;
    } catch (e) {
      print("Error updating ingrediente: $e");
      return false;
    }
  }

  Future<bool> deleteIngrediente(String id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$hostName/ingredientes/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        fetchIngredientes(token);
        return true;
      }
      return false;
    } catch (e) {
      print("Error deleting ingrediente: $e");
      return false;
    }
  }
}
