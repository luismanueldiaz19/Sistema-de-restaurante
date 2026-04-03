class User {
  final int id;
  final String? name;
  final String? email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name'], email: json['email']);
  }
}

class AuthResponse {
  final bool status;
  final User user;
  final List<String> roles;
  final List<String> permissions;
  final String token;

  AuthResponse({
    required this.status,
    required this.user,
    required this.roles,
    required this.permissions,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data']; // 👈 CLAVE
    return AuthResponse(
      status: json['status'],
      user: User.fromJson(data['user']),
      roles: List<String>.from(data['roles']),
      permissions: List<String>.from(data['permissions']),
      token: data['token'],
    );
  }
}
