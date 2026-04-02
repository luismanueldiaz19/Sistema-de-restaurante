import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sistema_restaurante/palletes/app_colors.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool? obscureText = true;
  final FocusNode _focusNode = FocusNode();
  late TextEditingController controllerUsuario = TextEditingController(
    text: 'lwader@gmail.com',
  );
  late TextEditingController controllerClave = TextEditingController(
    text: '199512',
  );
  final authService = AuthService();

  bool isLoading = false;

  void iniciarSeccion() async {
    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      controllerUsuario.text,
      controllerClave.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MyHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales incorrectas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    controllerClave.dispose();
    controllerUsuario.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Shader linearGradient = const LinearGradient(
      colors: <Color>[AppColors.azulOscuro, AppColors.azulClaro],
    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 125.0));

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ZoomIn(
              curve: Curves.decelerate,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420, // 👈 ancho máximo PRO
                ),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ===== LOGO / NOMBRE =====
                        Text(
                          'Lwader Soft',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            foreground: Paint()..shader = linearGradient,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text('Iniciar sesión', style: textTheme.bodyMedium),

                        const SizedBox(height: 32),

                        // ===== USUARIO =====
                        textFieldWidgetUI(
                          label: 'Usuario',
                          controller: controllerUsuario,
                          onEditingComplete: () {
                            _focusNode.nextFocus();
                          },
                        ),

                        // ===== CLAVE =====
                        textFieldWidgetUI(
                          label: 'Clave',
                          obscureText: obscureText,
                          focusNode: _focusNode,
                          controller: controllerClave,
                          onEditingComplete: () => iniciarSeccion(),

                          // isPassword: true, // si lo soporta tu helper
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Quiere mostrar contraseña ?',
                              style: textTheme.bodySmall!.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  obscureText = !obscureText!;
                                });
                              },
                              child: Text(
                                'click Aqui!',
                                style: textTheme.bodySmall!.copyWith(
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: isLoading ? null : iniciarSeccion,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Iniciar sesión'),
                        ),
                        // Center(
                        //   child: CustomLoginButton(
                        //     onPressed:isLoading ? null : iniciarSeccion,
                        //     text: 'Iniciar sesión',
                        //   ),
                        // ),
                        const SizedBox(height: 16),

                        // ===== FOOTER =====
                        identy(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
