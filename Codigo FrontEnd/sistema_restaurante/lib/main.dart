import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'modulo_cliente/providers/cliente_admin_provider.dart';
// import 'modulo_cliente/screens/screen_client_admin.dart';
import 'providers/auth_provider.dart';
import 'providers/factura_provider.dart';
import 'screens/login_page.dart';
import 'services/api_services.dart';
import 'utils/navigation_service.dart';

bool _isLoggingOut = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    final authProvider = AuthProvider(); // ✅ UNA sola instancia

    ApiService.onUnauthorized = () async {
      if (_isLoggingOut) return;

      _isLoggingOut = true;

      // final context = NavigationService.navigatorKey.currentState?.context;
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sesión expirada"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 300)); // 🔥 UX PRO
      await authProvider.logout();

      NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );

      _isLoggingOut = false;
    };
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider), // 🔥 ESTE ES CLAVE
        ChangeNotifierProvider(create: (_) => ClienteAdminProvider()),
        ChangeNotifierProvider(create: (_) => FacturaProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
