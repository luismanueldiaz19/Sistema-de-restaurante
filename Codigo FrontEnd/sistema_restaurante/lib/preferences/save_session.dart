// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../screens/splash_screen.dart';

// Future<void> saveSession(Map<String, dynamic> data) async {
//   final prefs = await SharedPreferences.getInstance();

//   await prefs.setString('token', data['token']);
//   await prefs.setString('user', jsonEncode(data['user']));
//   await prefs.setStringList('roles', List<String>.from(data['roles']));
//   await prefs.setStringList(
//     'permissions',
//     List<String>.from(data['permissions']),
//   );
// }

// Future<bool> hasSession() async {
//   final prefs = await SharedPreferences.getInstance();
//   final token = prefs.getString('token');

//   return token != null && token.isNotEmpty;
// }

// // Future<void> logout(BuildContext context) async {
// //   final prefs = await SharedPreferences.getInstance();

// //   await prefs.clear(); // elimina todo

// //   if (!context.mounted) return;

// //   Navigator.pushAndRemoveUntil(
// //     context,
// //     MaterialPageRoute(builder: (context) => const SplashScreen()),
// //     (route) => false,
// //   );
// // }
