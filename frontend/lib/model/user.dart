class User {
  final int? id;
  final String? name;
  final String? email;
  final String? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    this.name,
    this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    emailVerifiedAt: json["email_verified_at"],
    createdAt: json["created_at"] != null
        ? DateTime.parse(json["created_at"] ?? '')
        : null,
    updatedAt: json["updated_at"] != null
        ? DateTime.parse(json["updated_at"] ?? '')
        : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "email_verified_at": emailVerifiedAt,
    "created_at": createdAt.toString(),
    "updated_at": updatedAt.toString(),
  };
}
// class AuthResponse {
//     final bool? success;
//     final String? message;
//     final User? user;
//     final List<String>? roles;
//     final List<String>? permissions;
//     final String? token;

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
