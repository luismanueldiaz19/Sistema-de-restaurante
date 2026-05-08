import '../model/user.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? token;
  final User? user;
  final List<String> roles;
  final List<String> permissions;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.token,
    this.user,
    this.roles = const [],
    this.permissions = const [],
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? token,
    User? user,
    List<String>? roles,
    List<String>? permissions,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      user: user ?? this.user,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }

  /// 🔐 VALIDAR PERMISOS (CON LÓGICA DE SUPERUSUARIO)
  bool hasPermission(String permissionName) {
    if (roles.contains('admin')) return true;
    return permissions.contains(permissionName);
  }
}
