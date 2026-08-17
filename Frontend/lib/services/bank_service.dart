import 'dart:convert';
import 'package:sistema_restaurante/model/banco_models.dart';
import 'package:sistema_restaurante/services/api_services.dart';
import 'package:sistema_restaurante/utils/constants.dart';

class BankService {
  final ApiService _api = ApiService();
  final String _baseUrl = '$hostName/api';

  // ================= BANCOS =================

  Future<List<BankModel>> getBanks({required String token}) async {
    final response = await _api.get('$_baseUrl/bancos', token: token);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'];
      return data.map((e) => BankModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener bancos');
  }

  Future<BankModel> createBank(String token, Map<String, dynamic> data) async {
    final response = await _api.post('$_baseUrl/bancos', data, token: token);
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return BankModel.fromJson(decoded['data']);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Error al crear banco');
  }

  // ================= CUENTAS BANCARIAS =================

  Future<List<BankAccountModel>> getBankAccounts({required String token}) async {
    final response = await _api.get('$_baseUrl/cuentas-bancarias', token: token);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'];
      return data.map((e) => BankAccountModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener cuentas bancarias');
  }

  Future<BankAccountModel> createBankAccount(String token, Map<String, dynamic> data) async {
    final response = await _api.post('$_baseUrl/cuentas-bancarias', data, token: token);
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return BankAccountModel.fromJson(decoded['data']);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Error al crear cuenta bancaria');
  }

  Future<void> deleteBankAccount(String token, int id) async {
    final response = await _api.delete('$_baseUrl/cuentas-bancarias/$id', token: token);
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al eliminar cuenta bancaria');
    }
  }

  // ================= TRANSACCIONES BANCARIAS =================

  Future<List<BankTransactionModel>> getBankTransactions({required String token, int? accountId}) async {
    String url = '$_baseUrl/transacciones-bancarias';
    if (accountId != null) {
      url += '?bank_account_id=$accountId';
    }
    final response = await _api.get(url, token: token);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'];
      return data.map((e) => BankTransactionModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener transacciones bancarias');
  }

  Future<BankTransactionModel> createBankTransaction(String token, Map<String, dynamic> data) async {
    final response = await _api.post('$_baseUrl/transacciones-bancarias', data, token: token);
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return BankTransactionModel.fromJson(decoded['data']);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Error al registrar transacción bancaria');
  }

  Future<void> reconcileBankTransactions(String token, List<int> transactionIds) async {
    final response = await _api.post('$_baseUrl/transacciones-bancarias/conciliar', {
      'transaction_ids': transactionIds
    }, token: token);
    
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al conciliar transacciones');
    }
  }
}
