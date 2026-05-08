import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/palletes/app_colors.dart';
import 'package:sistema_restaurante/services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../utils/constants.dart';
import 'button_menu_drawer.dart';

class Menudrop extends ConsumerStatefulWidget {
  const Menudrop({super.key, this.isMobile = false});
  final bool isMobile;

  @override
  ConsumerState<Menudrop> createState() => _MenudropState();
}

class _MenudropState extends ConsumerState<Menudrop> {
  final auth = AuthService();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final style = Theme.of(context).textTheme;

    final double menuWidth = widget.isMobile
        ? size.width * 0.7
        : (size.width > 1400 ? 280 : 240);

    final double fontSize = widget.isMobile ? 15 : 14;
    final double fontSizeSubtitle = widget.isMobile ? 15 : 12;
    return Container(
      color: AppColors.grisClaro,
      height: size.height,
      width: menuWidth,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.isMobile
                ? Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    child: Image.asset(logoApp, fit: BoxFit.cover, scale: 10),
                  )
                : const SizedBox(height: 10),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  showTrailingIcon: false,
                  subtitle: Text(
                    'Ver y gestionar Cuenta',
                    style: style.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontSize: fontSizeSubtitle,
                    ),
                  ),
                  title: Text(
                    'Mi Cuenta',
                    style: style.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: fontSize,
                    ),
                  ),
                  children: const [
                    MyWidgetButton(
                      icon: Icons.home_outlined,
                      textButton: 'Inicio',
                    ),
                    MyWidgetButton(
                      icon: Icons.person_3_outlined,
                      textButton: 'Mi Perfil',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: MyWidgetButton(
                icon: Icons.logout,
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Cerrar sesión"),
                      content: const Text("¿Seguro que deseas salir?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);

                            // Usar Riverpod para cerrar sesión
                            await ref.read(authProvider.notifier).logout();

                            if (!context.mounted) return;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SplashScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text("Salir"),
                        ),
                      ],
                    ),
                  );
                },
                textButton: 'Cerrar sección',
                colorIcon: Colors.red,
                textColor: Colors.redAccent.shade700,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: 10,
                hoverColor: Colors.redAccent.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
