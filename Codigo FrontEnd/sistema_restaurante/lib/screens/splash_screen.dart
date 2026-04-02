import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../palletes/app_colors.dart';
import '../preferences/save_session.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late AnimationController _controller;
  late List<Animation<Offset>> _letterAnimations;

  final String text1 = 'Lwader';
  final String text2 = 'Soft';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _createAnimations();
    _controller.forward();

    _checkSession();
  }

  void _createAnimations() {
    final totalLetters = text1.length + text2.length;

    _letterAnimations = List.generate(totalLetters, (index) {
      final start = index / totalLetters;
      final end = start + (1 / totalLetters);
      return Tween<Offset>(
        begin: const Offset(0, -1.5), // cae desde arriba
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    final auth = context.read<AuthProvider>();

    await auth.loadSession(); // 🔥 carga token + user

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            auth.isAuthenticated ? const MyHomePage() : const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    int animationIndex = 0;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ===== TEXTO ANIMADO =====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...text1.split('').map((letter) {
                  final anim = _letterAnimations[animationIndex++];
                  return SlideTransition(
                    position: anim,
                    child: Text(
                      letter,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.azulOscuro,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                ...text2.split('').map((letter) {
                  final anim = _letterAnimations[animationIndex++];
                  return SlideTransition(
                    position: anim,
                    child: Text(
                      letter,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.azulClaro,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 12),

            // ===== SUBTEXTO =====
            FadeTransition(
              opacity: _controller,
              child: Text('Verificando sesión...', style: textTheme.bodySmall),
            ),

            const SizedBox(height: 25),

            // ===== LOADING =====
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
