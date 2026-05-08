import 'package:flutter/material.dart';

class PermissionWidget extends StatelessWidget {
  final List<String> permissions;
  final String permiso;
  final Widget child;

  const PermissionWidget({
    super.key,
    required this.permissions,
    required this.permiso,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (permissions.contains(permiso)) {
      return child;
    }
    return SizedBox(); // o Container()
  }
}
