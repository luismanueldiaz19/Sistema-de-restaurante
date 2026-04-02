import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;

  String? _token;
  User? _user; // 🔥 CAMBIO IMPORTANTE
  List<String> _roles = [];
  List<String> _permissions = [];

  // GETTERS
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  User? get user => _user; // 🔥 ya no es Map
  List<String> get roles => _roles;
  List<String> get permissions => _permissions;

  /// 🔐 LOGIN

  /// 🔐 LOGIN (🔥 FIXED)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final AuthResponse? result = await _authService.login(
      email: email,
      password: password,
    );

    if (result != null && result.status) {
      _token = result.token;
      _user = result.user; // 🔥 ya es User
      _roles = result.roles;
      _permissions = result.permissions;
      _isAuthenticated = true;

      await _saveSession();

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 💾 GUARDAR SESIÓN
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', _token!);

    await prefs.setString(
      'user',
      jsonEncode({'id': _user!.id, 'name': _user!.name, 'email': _user!.email}),
    );

    await prefs.setStringList('roles', _roles);
    await prefs.setStringList('permissions', _permissions);
  }

  /// 🔄 CARGAR SESIÓN (AUTO LOGIN)
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('token');
    final userStr = prefs.getString('user');

    if (_token != null && userStr != null) {
      _user = User.fromJson(jsonDecode(userStr));
      _roles = prefs.getStringList('roles') ?? [];
      _permissions = prefs.getStringList('permissions') ?? [];
      _isAuthenticated = true;
    }

    notifyListeners();
  }

  /// 🚪 LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    _token = null;
    _user = null;
    _roles = [];
    _permissions = [];
    _isAuthenticated = false;

    notifyListeners();
  }

  /// 🔐 VALIDAR PERMISOS
  bool hasPermission(String permission) {
    return _permissions.contains(permission);
  }
}
