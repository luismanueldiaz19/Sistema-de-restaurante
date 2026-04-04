import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'modulo_cliente/providers/cliente_admin_provider.dart';
// import 'modulo_cliente/screens/screen_client_admin.dart';
import 'providers/auth_provider.dart';
import 'providers/factura_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ClienteAdminProvider>(
          create: (_) => ClienteAdminProvider(),
          update: (_, auth, clienteProvider) {
            if (auth.token != null) {
              clienteProvider!.loadClients(auth.token!);
            }
            return clienteProvider!;
          },
        ),

        ChangeNotifierProvider(create: (_) => FacturaProvider()),
        // FacturaProvider
      ],
      child: const MyApp(),
    ),
  );
}
