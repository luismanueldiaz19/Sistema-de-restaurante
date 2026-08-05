import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/palletes/app_colors.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_loading.dart';
import 'home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  bool? obscureText = true;
  final FocusNode _focusNode = FocusNode();
  late TextEditingController controllerUsuario = TextEditingController(
    text: 'lwader@gmail.com',
  );
  late TextEditingController controllerClave = TextEditingController(
    text: '199512',
  );

  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'Admin',
      'email': 'lwader@gmail.com',
      'pass': '199512',
      'icon': Icons.admin_panel_settings_outlined,
    },
    {
      'name': 'Cajero',
      'email': 'cajero@gmail.com',
      'pass': 'cajero123',
      'icon': Icons.person_outline,
    },
    // {
    //   'name': 'Cajero 2',
    //   'email': 'cajero2@gmail.com',
    //   'pass': 'cajero123',
    //   'icon': Icons.person_add_alt_1_outlined,
    // },
  ];
  int _selectedProfileIndex = 0;

  void _selectProfile(int index) {
    setState(() {
      _selectedProfileIndex = index;
      controllerUsuario.text = _profiles[index]['email']!;
      controllerClave.text = _profiles[index]['pass']!;
    });
  }

  final authService = AuthService();
  bool isLoading = false;

  late AnimationController _animationController;

  bool showBorderGlow = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Esperar a que el ZoomIn termine (600ms) para iniciar el giro del borde
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => showBorderGlow = true);
        _animationController.repeat();
      }
    });
  }

  void iniciarSeccion() async {
    setState(() => isLoading = true);

    // 1. Mostrar Dialogo de Carga (CustomLoading)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CustomLoading(
              text: 'Autenticando sesión...',
              size: 110,
            ),
          ),
        ),
      ),
    );

    final auth = ref.read(authProvider.notifier);

    final success = await auth.login(
      controllerUsuario.text,
      controllerClave.text,
    );

    if (!mounted) return;

    if (success) {
      // Esperar 3 segundos solo si el login es correcto
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
    }

    // 2. Cerrar Dialogo
    Navigator.pop(context);

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    } else {
      showToast(context, 'Credenciales incorrectas', bgColor: Colors.red);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    controllerClave.dispose();
    controllerUsuario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(backgroundCafeteria, fit: BoxFit.cover),
          ),
          // 2. Overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
          // 3. Center Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ZoomIn(
                animate: showBorderGlow,
                duration: const Duration(milliseconds: 600),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        // Grosor del borde (1.5px)
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.5),
                          gradient: showBorderGlow
                              ? SweepGradient(
                                  center: Alignment.center,
                                  transform: GradientRotation(
                                    _animationController.value * 2 * math.pi,
                                  ),
                                  colors: const [
                                    Colors.transparent,
                                    AppColors.success,
                                    Colors.transparent,
                                  ],
                                  stops: const [0.4, 0.5, 0.6],
                                )
                              : null,
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Left Section (Branding)
                            if (size.width > 850)
                              Expanded(
                                flex: 1,
                                child: Container(
                                  color: AppColors.white,
                                  padding: const EdgeInsets.all(30),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Spacer(),
                                      Text(
                                        appName[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 140,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                          fontFamily: 'Serif',
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '© ${appName.toUpperCase()} SOFT, INC.',
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.grey.shade500,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'HANDCRAFTED BY ${developer.toUpperCase()}',
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.grey.shade400,
                                          fontSize: 9,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // 2. Right Section (Form)
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 50,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: size.width > 850
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '¡Bienvenido!',
                                      style: textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.azulOscuro,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Inicia sesión para continuar',
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    /// 👤 SELECTOR DE PERFIL (SLIDER / TABS)
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: List.generate(
                                          _profiles.length,
                                          (index) {
                                            final isSelected =
                                                _selectedProfileIndex == index;
                                            final profile = _profiles[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              child: InkWell(
                                                onTap: () =>
                                                    _selectProfile(index),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? AppColors.azulOscuro
                                                        : Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                    boxShadow: isSelected
                                                        ? [
                                                            BoxShadow(
                                                              color: AppColors
                                                                  .azulOscuro
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    4,
                                                                  ),
                                                            ),
                                                          ]
                                                        : [],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        profile['icon'],
                                                        size: 18,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Colors
                                                                  .grey
                                                                  .shade600,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        profile['name'],
                                                        style: TextStyle(
                                                          color: isSelected
                                                              ? Colors.white
                                                              : Colors
                                                                    .grey
                                                                    .shade600,
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 40),

                                    // USER FIELD
                                    textFieldWidgetUI(
                                      label: 'Código de empleado',
                                      prefixIcon: Icons.badge_outlined,
                                      controller: controllerUsuario,
                                      onEditingComplete: () =>
                                          _focusNode.requestFocus(),
                                    ),

                                    // PASSWORD FIELD
                                    textFieldWidgetUI(
                                      label: 'Clave / PIN',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: obscureText,
                                      focusNode: _focusNode,
                                      controller: controllerClave,
                                      suffixIcon: obscureText!
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      onSuffixTap: () {
                                        setState(
                                          () => obscureText = !obscureText!,
                                        );
                                      },
                                      onEditingComplete: iniciarSeccion,
                                    ),

                                    const SizedBox(height: 40),

                                    // LOGIN BUTTON
                                    CustomButton(
                                      width: 250,
                                      title: 'INGRESAR',
                                      isLoading: isLoading,
                                      onPressed: iniciarSeccion,
                                      backgroundColor: AppColors.secondary,
                                    ),

                                    const SizedBox(height: 24),
                                    Center(
                                      child: TextButton(
                                        onPressed: () {},
                                        child: Text(
                                          '¿Olvidaste tu acceso? Contacta a Soporte',
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
