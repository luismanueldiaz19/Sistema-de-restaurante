import 'package:flutter/material.dart';
import '../palletes/app_colors.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;
  final bool isLoading;
  final Color? backgroundColor;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (backgroundColor != null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: color ?? Colors.white, size: size),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      );
    }

    return IconButton(
      icon: Icon(icon, color: color ?? AppColors.primary, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
