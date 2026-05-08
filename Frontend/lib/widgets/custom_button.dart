import 'package:flutter/material.dart';
import '../palletes/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final IconData? icon;
  final bool enabled;
  final double borderRadius;
  final double fontSize;
  final bool isFlat;

  const CustomButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 58,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.isLoading = false,
    this.icon,
    this.enabled = true,
    this.borderRadius = 12,
    this.fontSize = 16,
    this.isFlat = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFlat) {
      return SizedBox(
        width: width,
        height: height,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: backgroundColor ?? AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          onPressed: (enabled && !isLoading) ? onPressed : null,
          child: _buildChild(),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.secondary,
          foregroundColor: foregroundColor,
          disabledBackgroundColor:
              (backgroundColor ?? AppColors.secondary).withOpacity(0.6),
          disabledForegroundColor: foregroundColor?.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: enabled && !isLoading ? 8 : 0,
          shadowColor: (backgroundColor ?? AppColors.secondary).withOpacity(0.4),
        ),
        onPressed: (enabled && !isLoading) ? onPressed : null,
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
