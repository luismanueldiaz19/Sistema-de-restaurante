import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_restaurante/screens/splash_screen.dart';

import 'palletes/app_colors.dart';
import 'theme/lwader_soft_theme.dart';
import 'utils/constants.dart';
import 'utils/navigation_service.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      navigatorKey: NavigationService.navigatorKey, // 👈 CLAVE
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.light,
          error: AppColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          scrolledUnderElevation:
              0, // 👈 Evita el cambio de color al hacer scroll
          surfaceTintColor: Colors.transparent, // 👈 Evita el tinte crema/beige
          elevation: 0,
        ),
        extensions: <ThemeExtension<dynamic>>[
          const LwaderSoftTheme(
            dataTableHeader: AppColors.secondary,
            dataTableRow: AppColors.light,
            cardBackground: AppColors.white,
            snackbarBackground: AppColors.secondary,
            snackbarText: AppColors.white,
          ),
        ],
      ),
      home: SplashScreen(),
    );
  }
}
