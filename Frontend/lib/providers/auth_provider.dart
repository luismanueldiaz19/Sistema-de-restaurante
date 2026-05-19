import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';
import '../modulo_caja/providers/caja_provider.dart';
import '../facturacion/providers/facturacion_provider.dart';
import '../facturacion/providers/facturacion_historial_provider.dart';
import '../modulo_cliente/providers/cliente_admin_provider.dart';
import '../modulo_producto/providers/producto_provider.dart';
import '../modulo_producto/providers/ingrediente_provider.dart';
import 'configuracion_contable_provider.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    // Intentar cargar sesión al inicializar
    Future.microtask(() => loadSession());
    return AuthState();
  }

  /// 🔐 LOGIN
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    final AuthResponse? result = await _authService.login(
      email: email,
      password: password,
    );

    if (!ref.mounted) return false;

    if (result != null && result.status) {
      state = state.copyWith(
        token: result.token,
        user: result.user,
        roles: result.roles,
        permissions: result.permissions,
        isAuthenticated: true,
        isLoading: false,
      );

      await _saveSession();
      return true;
    }

    state = state.copyWith(isLoading: false);
    return false;
  }

  /// 💾 GUARDAR SESIÓN
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;

    if (state.token != null) {
      await prefs.setString('token', state.token!);
    }
    if (state.user != null) {
      await prefs.setString(
        'user',
        jsonEncode({
          'id': state.user!.id,
          'name': state.user!.name,
          'email': state.user!.email,
        }),
      );
    }
    await prefs.setStringList('roles', state.roles);
    await prefs.setStringList('permissions', state.permissions);
  }

  /// 🔄 CARGAR SESIÓN (AUTO LOGIN)
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;

    final token = prefs.getString('token');
    final userStr = prefs.getString('user');

    if (token != null && userStr != null) {
      final user = User.fromJson(jsonDecode(userStr));
      final roles = prefs.getStringList('roles') ?? [];
      final permissions = prefs.getStringList('permissions') ?? [];

      if (ref.mounted) {
        state = state.copyWith(
          token: token,
          user: user,
          roles: roles,
          permissions: permissions,
          isAuthenticated: true,
        );
      }
    }
  }

  /// 🚪 LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (ref.mounted) {
      state = AuthState();

      // Limpiar proveedores de datos sensibles
      ref.invalidate(cajaProvider);
      ref.invalidate(facturacionProvider);
      ref.invalidate(facturacionHistorialProvider);
      ref.invalidate(clienteAdminProvider);
      ref.invalidate(productoProvider);
      ref.invalidate(ingredienteProvider);
      ref.invalidate(configuracionContableProvider);
    }
  }

  /// 🔐 VALIDAR PERMISOS (CON LÓGICA DE SUPERUSUARIO)
  bool hasPermission(String permission) {
    // Si el usuario es administrador, tiene acceso total (bypass)
    if (state.roles.contains('admin')) return true;

    // Si no es admin, verificamos el permiso específico
    return state.permissions.contains(permission);
  }
}
