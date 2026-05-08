import 'package:flutter/material.dart';
import '../palletes/app_colors.dart';

class MainButtonStyle extends StatelessWidget {
  const MainButtonStyle({
    super.key,
    required this.onPress,
    required this.text,
    required this.image,
    this.textTitle,
    this.height = 150,
    this.width = 150,
  });

  final VoidCallback onPress;
  final String text;
  final String image;
  final String? textTitle;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: 4,
        color: Colors.white,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPress,
          splashColor: AppColors.azulOscuro.withValues(alpha: 0.2),
          highlightColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: Image.asset(image, fit: BoxFit.cover)),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  textTitle ?? 'Zona',
                  style: theme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
