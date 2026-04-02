import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_restaurante/screens/splash_screen.dart';

import 'palletes/app_colors.dart';
import 'theme/lwader_soft_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lwader Soft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        fontFamily: 'Inter',
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.azulMedio,
          secondary: AppColors.azulClaro,
          surface: AppColors.grisClaro,
          error: AppColors.error,
        ),
        extensions: <ThemeExtension<dynamic>>[
          const LwaderSoftTheme(
            dataTableHeader: AppColors.azulOscuro,
            dataTableRow: AppColors.grisClaro,
            cardBackground: AppColors.blanco,
            snackbarBackground: AppColors.azulOscuro,
            snackbarText: AppColors.blanco,
          ),
        ],
      ),
      home: SplashScreen(),
    );
  }
}
